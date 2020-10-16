defmodule LiveDjWeb.Room.ShowLive do
  @moduledoc """
  A LiveView for creating and joining rooms.
  """

  use LiveDjWeb, :live_view

  alias LiveDj.Organizer
  alias LiveDj.Organizer.Player
  alias LiveDj.Organizer.Video
  alias LiveDj.ConnectedUser
  alias LiveDjWeb.Presence
  alias Phoenix.Socket.Broadcast

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    user = create_connected_user()
    room = Organizer.get_room(slug)
    Phoenix.PubSub.subscribe(LiveDj.PubSub, "room:" <> slug)

    {:ok, _} = Presence.track(self(), "room:" <> slug, user.uuid, %{})

    case room do
      nil ->
        {:ok,
          socket
          |> put_flash(:error, "That room does not exist.")
          |> push_redirect(to: Routes.new_path(socket, :new))
        }
      room ->
        player = Player.get_initial_state()
        {:ok,
          socket
          |> assign(:user, user)
          |> assign(:slug, slug)
          |> assign(:connected_users, [])
          |> assign(:video_queue, [])
          |> assign(:search_result, fake_search_data())
          |> assign(:player, player)
          |> assign(:player_controls, Player.get_controls_state(player))
          |> assign_tracker(room)
        }
    end
  end

  @impl true
  def handle_info(
    %Broadcast{event: "presence_diff", payload: payload},
    %{assigns: %{slug: slug, user: user}} = socket
  ) do
    connected_users = Organizer.list_present(slug)

    room = handle_video_tracker_activity(slug, connected_users, payload)

    updated_socket = socket
    |> assign(:connected_users, connected_users)
    |> assign(:room, room)

    # TODO: refactor, there should be a way to receive the diff event only when
    # others joined
    case Organizer.is_my_presence(user, payload) do
      false ->
        {:noreply,
          updated_socket
          |> push_event("presence-changed", %{})
        }
      true ->
        {:noreply, updated_socket}
    end
  end

  def handle_info(
    {:add_to_queue, %{updated_video_queue: updated_video_queue}},
    %{assigns: %{player: player, search_result: search_result}} = socket
  ) do
    search_result = search_result
      |> Enum.map(fn search -> mark_as_queued(search, updated_video_queue) end)

    socket = socket
      |> assign(:search_result, search_result)
      |> assign(:video_queue, updated_video_queue)

    case updated_video_queue do
      [v] ->
        selected_video = v
        props = %{time: 0, video_id: selected_video.video_id, state: "playing"}
        player = Player.update(player, props)
        {:noreply,
          socket
          |> assign(:player, player)
          |> assign(:player_controls, Player.get_controls_state(player))
          |> push_event("receive_player_state", Player.create_response(player))
        }
      [_v|_vs] ->
        case player.state do
          "stopped" ->
            %{video_id: video_id} = player
            next_video = Enum.find(updated_video_queue, fn video -> video.previous == video_id end)
            %{video_id: video_id} = next_video
            player = Player.update(player, %{state: "playing", time: 0, video_id: video_id})
            {:noreply,
              socket
              |> assign(:player, player)
              |> assign(:player_controls, Player.get_controls_state(player))
              |> push_event("receive_player_state", Player.create_response(player))}
          _ ->
            {:noreply,
              socket
              |> push_event("receive_queue_changed", %{})}
        end
    end
  end

  def handle_info({:request_initial_state, _params}, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    :ok = Phoenix.PubSub.broadcast_from(
      LiveDj.PubSub,
      self(),
      "room:" <> socket.assigns.slug <> ":request_initial_state",
      {:receive_initial_state, %{current_queue: video_queue, player: player}}
    )
    {:noreply, socket}
  end

  def handle_info({:receive_initial_state, params}, socket) do
    %{search_result: search_result, slug: slug} = socket.assigns
    Organizer.unsubscribe(:request_initial_state, slug)
    %{current_queue: current_queue, player: player} = params
    search_result = search_result
      |> Enum.map(fn search -> mark_as_queued(search, current_queue) end)
    socket = socket
      |> assign(:video_queue, current_queue)
      |> assign(:player, player)
      |> assign(:player_controls, Player.get_controls_state(player))
      |> assign(:search_result, search_result)
    case current_queue do
      []  -> {:noreply, socket}
      _xs ->
        {:noreply,
          socket
          |> push_event("receive_player_state", Player.create_response(player))}
    end
  end

  def handle_info({:player_signal_playing, %{state: state}}, socket) do
    %{player: player} = socket.assigns
    player = Player.update(player, %{state: state})
    {:noreply,
      socket
      |> assign(:player, player)
      |> assign(:player_controls, Player.get_controls_state(player))
      |> push_event("receive_playing_signal", %{})}
  end

  def handle_info({:player_signal_paused, %{state: state}}, socket) do
    %{player: player} = socket.assigns
    player = Player.update(player, %{state: state})
    {:noreply,
    socket
      |> assign(:player, player)
      |> assign(:player_controls, Player.get_controls_state(player))
      |> push_event("receive_paused_signal", %{})}
  end

  def handle_info({:player_signal_current_time, %{time: time}}, socket) do
    %{player: player} = socket.assigns
    {:noreply,
    socket
      |> assign(:player, Player.update(player, %{time: time}))}
  end

  @impl true
  def handle_event("player_signal_ready", _, socket) do
    %{player: player, room: room, user: user} = socket.assigns

    presence = Organizer.list_filtered_present(room.slug, user.uuid)

    case presence do
      []  ->
        %{video_queue: video_queue} = socket.assigns
        case video_queue do
          [] ->
            {:noreply,
              socket
              |> assign(:player_controls, Player.get_controls_state(player))}
          [v|_vs]  ->
            player = Player.update(player, %{video_id: v.video_id})
            {:noreply,
              socket
              |> assign(:video_queue, video_queue)
              |> assign(:player_controls, player)
              |> push_event("receive_player_state", Player.create_response(player))}
        end
      _xs ->
        Organizer.subscribe(:request_initial_state, socket.assigns.slug)
        # Tells every node the requester node needs an initial state
        :ok = Phoenix.PubSub.broadcast_from(
          LiveDj.PubSub,
          self(),
          "room:" <> socket.assigns.slug,
          {:request_initial_state, %{}}
        )
        {:noreply, socket}
    end
  end

  def handle_event("player_signal_playing", _params, socket) do
    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:player_signal_playing, %{state: "playing"}}
    )
    {:noreply, socket}
  end

  def handle_event("player_signal_paused", _params, socket) do
    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:player_signal_paused, %{state: "paused"}}
    )
    {:noreply, socket}
  end

  def handle_event("player_signal_play_next", _params, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    %{video_id: current_video_id} = player

    next_video = Enum.find(video_queue, fn video -> video.previous == current_video_id end)

    case next_video do
      nil ->
        player = Player.update(player, %{state: "stopped", time: 0})
        {:noreply,
          socket
          |> assign(:player, player)
          |> assign(:player_controls, Player.get_controls_state(player))}
      video ->
        %{video_id: video_id} = video
        player = Player.update(player, %{video_id: video_id, time: 0, state: "playing"})
        {:noreply,
          socket
          |> assign(:player, player)
          |> assign(:player_controls, Player.get_controls_state(player))
          |> push_event("receive_player_state", Player.create_response(player))}
    end
  end

  @impl true
  def handle_event(
    "search",
    %{"search_field" => %{"query" => query}},
    %{assigns: %{video_queue: video_queue}} = socket
    ) do
    opts = [maxResults: 10]
    {:ok, search, _pagination_options} = Tubex.Video.search_by_query(query, opts)
    search_result = search
      |> Enum.map(fn search -> Video.from_tubex_video(search) end)
      |> Enum.map(fn video -> mark_as_queued(video, video_queue) end)
    {:noreply, assign(socket, :search_result, search_result)}
  end

  @impl true
  def handle_event("add_to_queue", selected_video, socket) do
    %{assigns: %{search_result: search_result, video_queue: video_queue}} = socket
    selected_video = Enum.find(search_result, fn search -> search.video_id == selected_video["video_id"] end)
    updated_video_queue = Player.add_to_queue(video_queue, selected_video)
    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:add_to_queue, %{updated_video_queue: updated_video_queue}}
    )
    {:noreply, socket}
  end


  @impl true
  def handle_event("player_signal_current_time", current_time, socket) do
    %{room: room, user: %{uuid: uuid}} = socket.assigns

    case uuid == room.video_tracker do
      true ->
        Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          "room:" <> socket.assigns.slug,
          {:player_signal_current_time, %{time: current_time}}
        )
        {:noreply, socket}
      false ->
        {:noreply, socket}
    end
  end

  defp handle_video_tracker_activity(slug, presence, %{leaves: leaves}) do
    room = Organizer.get_room(slug)
    video_tracker = room.video_tracker

    case video_tracker in Map.keys(leaves) do
      false -> room
      true  ->
        case presence do
          [] ->
            {:ok, updated_room} = Organizer.update_room(room, %{video_tracker: ""})
            updated_room
          [p|_ps] ->
            {:ok, updated_room} = Organizer.update_room(room, %{video_tracker: p})
            updated_room
        end
    end
  end

  defp create_connected_user do
    %ConnectedUser{uuid: UUID.uuid4()}
  end

  defp is_queued(video, video_queue) do
    Enum.any?(video_queue, fn qv -> qv.video_id == video.video_id end)
  end

  defp mark_as_queued(search, video_queue) do
    case is_queued(search, video_queue) do
      true -> Video.update(search, %{is_queued: "disabled"})
      false -> search
    end
  end

  defp assign_tracker(socket, room) do
    current_user = socket.assigns.user.uuid
    case Organizer.list_filtered_present(room.slug, current_user) do
      []  ->
        {:ok, updated_room} = Organizer.update_room(room, %{video_tracker: current_user})
        socket
        |> assign(:room, updated_room)
      _xs ->
        socket
        |> assign(:room, room)
    end
  end

  defp fake_video_queue do
    [
      %{
        "img_height" => "90",
        "img_url" => "https://i.ytimg.com/vi/r4G0nbpLySI/default.jpg",
        "img_width" => "120",
        "title" => "VULFPECK /// Wait for the Moment",
        "value" => "queue",
        "video_id" => "r4G0nbpLySI"
      },
      %{
        "img_height" => "90",
        "img_url" => "https://i.ytimg.com/vi/Qh3tnj13BiI/default.jpg",
        "img_width" => "120",
        "title" => "Charly García 25 Grandes Exitos Sus Mejores Canciones",
        "value" => "queue",
        "video_id" => "Qh3tnj13BiI"
      },
      %{
        "img_height" => "90",
        "img_url" => "https://i.ytimg.com/vi/myzNf5kW1kQ/default.jpg",
        "img_width" => "120",
        "title" => "wait for the moment | vulfpeck | ‘stories’ acoustic cover ft. hunter elizabeth wait for the moment | vulfpeck | ‘stories’ acoustic cover ft. hunter elizabeth wait for the moment | vulfpeck | ‘stories’ acoustic cover ft. hunter elizabeth",
        "value" => "queue",
        "video_id" => "myzNf5kW1kQ"
      }
    ]
  end

  defp fake_search_data do
    search_data = [
      %Tubex.Video{
        channel_id: "UCK5zTxgu4T8xLs0z5VBoIhg",
        channel_title: "Bảo Anh",
        description: "",
        etag: nil,
        playlist_id: nil,
        published_at: "2012-12-23T09:47:11Z",
        thumbnails: %{
          "default" => %{
            "height" => 90,
            "url" => "https://i.ytimg.com/vi/dyp2mLYhRkw/default.jpg",
            "width" => 120
          },
          "high" => %{
            "height" => 360,
            "url" => "https://i.ytimg.com/vi/dyp2mLYhRkw/hqdefault.jpg",
            "width" => 480
          },
          "medium" => %{
            "height" => 180,
            "url" => "https://i.ytimg.com/vi/dyp2mLYhRkw/mqdefault.jpg",
            "width" => 320
          }
        },
        title: "Video Countdown 20 Old  3 seconds",
        video_id: "dyp2mLYhRkw"
      },
      %Tubex.Video{
        channel_id: "UCLoZ-xYlaY7udYHFjgm55Hw",
        channel_title: "DiaryBela",
        description: "If you read this far down the description I love you. Please Hit that ▷ SUBSCRIBE button and LIKE my video and also turn ON notifications BELL! FOLLOW ...",
        etag: nil,
        playlist_id: nil,
        published_at: "2019-06-21T15:09:53Z",
        thumbnails: %{
          "default" => %{
            "height" => 90,
            "url" => "https://i.ytimg.com/vi/FJ5pRIZXVks/default.jpg",
            "width" => 120
          },
          "high" => %{
            "height" => 360,
            "url" => "https://i.ytimg.com/vi/FJ5pRIZXVks/hqdefault.jpg",
            "width" => 480
          },
          "medium" => %{
            "height" => 180,
            "url" => "https://i.ytimg.com/vi/FJ5pRIZXVks/mqdefault.jpg",
            "width" => 320
          }
        },
        title: "#1 Countdown | 3 seconds with sound effect",
        video_id: "FJ5pRIZXVks"
      },
      %Tubex.Video{
        channel_id: "UC-5mG3KEnJ4WUFXrGVUTHXw",
        channel_title: "bvbb",
        description: "my cat is epic.",
        etag: nil,
        playlist_id: nil,
        published_at: "2017-04-09T18:42:40Z",
        thumbnails: %{
          "default" => %{
            "height" => 90,
            "url" => "https://i.ytimg.com/vi/wUF9DeWJ0Dk/default.jpg",
            "width" => 120
          },
          "high" => %{
            "height" => 360,
            "url" => "https://i.ytimg.com/vi/wUF9DeWJ0Dk/hqdefault.jpg",
            "width" => 480
          },
          "medium" => %{
            "height" => 180,
            "url" => "https://i.ytimg.com/vi/wUF9DeWJ0Dk/mqdefault.jpg",
            "width" => 320
          }
        },
        title: "Video Countdown 3 seconds",
        video_id: "wUF9DeWJ0Dk"
      },
      %Tubex.Video{
        channel_id: "UCtWuB1D_E3mcyYThA9iKggQ",
        channel_title: "Vulf",
        description: "VULFPECK /// Dean Town buy on bandcamp → https://vulfpeck.bandcamp.com Jack Stratton — kick & snare, mixing, video Theo Katzman — sock cymbal ...",
        etag: nil,
        playlist_id: nil,
        published_at: "2016-10-11T17:01:52Z",
        thumbnails: %{
          "default" => %{
            "height" => 90,
            "url" => "https://i.ytimg.com/vi/le0BLAEO93g/default.jpg",
            "width" => 120
          },
          "high" => %{
            "height" => 360,
            "url" => "https://i.ytimg.com/vi/le0BLAEO93g/hqdefault.jpg",
            "width" => 480
          },
          "medium" => %{
            "height" => 180,
            "url" => "https://i.ytimg.com/vi/le0BLAEO93g/mqdefault.jpg",
            "width" => 320
          }
        },
        title: "VULFPECK /// Dean Town",
        video_id: "le0BLAEO93g"
      }
    ]
    Enum.map(search_data, fn e -> Video.from_tubex_video(e) end)
  end
end
