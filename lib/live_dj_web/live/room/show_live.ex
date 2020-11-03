defmodule LiveDjWeb.Room.ShowLive do
  @moduledoc """
  A LiveView for creating and joining rooms.
  """

  use LiveDjWeb, :live_view

  alias LiveDj.Organizer
  alias LiveDj.Organizer.Chat
  alias LiveDj.Organizer.Player
  alias LiveDj.Organizer.Queue
  alias LiveDj.Organizer.Video
  alias LiveDj.ConnectedUser
  alias LiveDjWeb.Presence
  alias Phoenix.Socket.Broadcast

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    user = create_connected_user()
    room = Organizer.get_room(slug)
    Phoenix.PubSub.subscribe(LiveDj.PubSub, "room:" <> slug)

    volume_data = %{volume_level: 100}

    {:ok, _} = Presence.track(self(), "room:" <> slug, user.uuid, Map.merge(volume_data, %{volume_icon: "fa-volume-up"}))

    parsed_queue = room.queue
    |> Enum.map(fn track -> Video.from_jsonb(track) end)

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
          |> assign(:new_message, "")
          |> assign(:messages, [])
          |> assign(:video_queue, Enum.with_index(parsed_queue))
          |> assign(:video_queue_controls, Queue.get_initial_controls())
          |> assign(:search_result, fake_search_data(parsed_queue))
          |> assign(:player, player)
          |> assign(:player_controls, Player.get_controls_state(player))
          |> assign(:volume_controls, volume_data)
          |> assign_tracker(room)
        }
    end
  end

  @impl true
  def handle_info(
    %Broadcast{event: "presence_diff", payload: payload},
    %{assigns: %{messages: messages, slug: slug, user: user}} = socket
  ) do

    connected_users = Organizer.list_present_with_metas(slug)

    room = handle_video_tracker_activity(slug, connected_users, payload)

    socket = socket
    |> assign(:connected_users, connected_users)
    |> assign(:room, room)

    # TODO: refactor, there should be a way to receive the diff event only when
    # others joined
    case Organizer.is_my_presence(user, payload) do
      false ->
        %{joins: joins, leaves: leaves} = payload
        joins = Map.to_list(joins)
          |> Enum.map(fn {uuid, _} -> Chat.create_message(:presence_joins, %{uuid: uuid}) end)
        leaves = Map.to_list(leaves)
          |> Enum.map(fn {uuid, _} -> Chat.create_message(:presence_leaves, %{uuid: uuid}) end)

        {:noreply,
          socket
          |> assign(:messages, messages ++ joins ++ leaves)
          |> push_event("presence-changed", %{})
        }
      true ->
        {:noreply, socket}
    end
  end

  def handle_info(
    {:add_to_queue, %{added_video_position: added_video_position, updated_video_queue: updated_video_queue, video_queue_controls: video_queue_controls}},
    %{assigns: %{player: player, search_result: search_result}} = socket
  ) do
    search_result = Enum.map(search_result, fn video ->
      Video.update(video, %{is_queued: Queue.is_queued(video, updated_video_queue)}) end)
    socket = socket
      |> assign(:search_result, search_result)
      |> assign(:video_queue, Enum.with_index(updated_video_queue))
      |> assign(:video_queue_controls, video_queue_controls)
      |> push_event("video_added_to_queue", %{pos: added_video_position})

    case updated_video_queue do
      [{v, _}] ->
        selected_video = v
        props = %{time: 0, video_id: selected_video.video_id, state: "playing", previous_id: "", next_id: ""}
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
            next_video = Queue.get_next_video(updated_video_queue, video_id)
            %{video_id: video_id} = next_video
            player = Player.update(player, %{state: "playing", time: 0, video_id: video_id})
            {:noreply,
              socket
              |> assign(:player, player)
              |> assign(:player_controls, Player.get_controls_state(player))
              |> push_event("receive_player_state", Player.create_response(player))}
          _ ->
            {:noreply, socket}
        end
    end
  end

  def handle_info({:save_queue, %{video_queue_controls: video_queue_controls}}, socket) do
    {:noreply,
      socket
      |> assign(:video_queue_controls, video_queue_controls)
      |> push_event("queue_saved", %{})}
  end

  def handle_info({:request_initial_state, _params}, socket) do
    %{messages: messages, video_queue: video_queue, player: player} = socket.assigns
    :ok = Phoenix.PubSub.broadcast_from(
      LiveDj.PubSub,
      self(),
      "room:" <> socket.assigns.slug <> ":request_initial_state",
      {:receive_initial_state, %{current_queue: video_queue, messages: messages, player: player}}
    )
    {:noreply, socket}
  end

  def handle_info({:receive_initial_state, params}, socket) do
    %{search_result: search_result, slug: slug} = socket.assigns
    Organizer.unsubscribe(:request_initial_state, slug)
    %{current_queue: current_queue, messages: messages, player: player} = params
    current_queue = Enum.map(current_queue, fn {v, _} -> v end)
    search_result = Enum.map(search_result, fn video ->
      Video.update(video, %{is_queued: Queue.is_queued(video, current_queue)}) end)
    socket = socket
      |> assign(:messages, messages)
      |> assign(:video_queue, Enum.with_index(current_queue))
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

# ===========================================================================
#
# Similar functions, refactor if not used to perform specific tasks
#

  def handle_info({:player_signal_play_next, %{player: player, player_controls: player_controls}}, socket) do
    {:noreply, socket
      |> assign(:player, player)
      |> assign(:player_controls, player_controls)
      |> push_event("receive_player_state", Player.create_response(player))}
  end

  def handle_info({:player_signal_play_previous, %{player: player, player_controls: player_controls}}, socket) do
    {:noreply, socket
      |> assign(:player, player)
      |> assign(:player_controls, player_controls)
      |> push_event("receive_player_state", Player.create_response(player))}
  end

#
# ===========================================================================

  def handle_info({:player_signal_play_by_id, %{video_id: video_id}}, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    selected_video = Queue.get_video_by_id(video_queue, video_id)

    case selected_video do
      nil -> {:noreply, socket}
      video ->
        params = %{
          next_id: video.next,
          previous_id: video.previous,
          time: 0,
          video_id: video.video_id,
        }
        player = Player.update(player, params)
        player_controls = Player.get_controls_state(player)
        {:noreply,
          socket
          |> assign(:player, player)
          |> assign(:player_controls, player_controls)
          |> push_event("receive_player_state", Player.create_response(player))}
    end
  end

  def handle_info({:volume_level_changed, params}, socket) do
    %{uuid: uuid, volume_level: volume_level, volume_icon: volume_icon} = params
    %{slug: slug} = socket.assigns

    Presence.update(self(), "room:" <> slug, uuid, fn m ->
      Map.merge(m, %{volume_level: volume_level, volume_icon: volume_icon})
    end)

    connected_users = Organizer.list_present_with_metas(slug)

    {:noreply,
      socket
      |> assign(:connected_users, connected_users)}
  end

  def handle_info({:remove_track, %{video_id: video_id}}, socket) do
    %{
      search_result: search_data,
      video_queue: video_queue,
      video_queue_controls: video_queue_controls
    } = socket.assigns

    video_queue = video_queue
    |> Enum.map(fn {v, _} -> v end)
    |> Queue.remove_video_by_id(video_id)

    {:noreply,
      socket
      |> assign(:search_result, Enum.map(search_data, fn video ->
        Video.update(video, %{is_queued: Queue.is_queued(video, video_queue)}) end))
      |> assign(:video_queue_controls, Queue.mark_as_unsaved(video_queue_controls))
      |> assign(:video_queue, Enum.with_index(video_queue))}
  end

  def handle_info({:player_signal_sort_video, params}, socket) do
    %{
      sorted_video_position: sorted_video_position,
      player: player,
      player_controls: player_controls,
      video_queue: video_queue,
      video_queue_controls: video_queue_controls
    } = params
    {:noreply,
    socket
      |> assign(:player, player)
      |> assign(:player_controls, player_controls)
      |> assign(:video_queue, video_queue)
      |> assign(:video_queue_controls, video_queue_controls)
      |> push_event("video_sorted_to_queue", %{pos: sorted_video_position})}
  end

  def handle_info({:player_signal_current_time, %{time: time}}, socket) do
    %{player: player} = socket.assigns
    {:noreply,
    socket
      |> assign(:player, Player.update(player, %{time: time}))}
  end

  def handle_info({:receive_messages, %{messages: messages}}, socket) do
    {:noreply,
      socket
      |> assign(:messages, messages)
      |> push_event("receive_new_message", %{})
    }
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
          [{v, _}|_vs]  ->
            player = Player.update(player, %{video_id: v.video_id, previous_id: v.previous, next_id: v.next})
            {:noreply,
              socket
              |> assign(:video_queue, video_queue)
              |> assign(:player, player)
              |> assign(:player_controls, Player.get_controls_state(player))
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

  def handle_event("player_signal_video_ended", _params, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    %{video_id: current_video_id} = player
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    next_video = Queue.get_next_video(video_queue, current_video_id)

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

# ===========================================================================
#
# Very similar functions, refactor if not used for a specific task
#

  def handle_event("player_signal_play_next", _params, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    %{video_id: current_video_id} = player
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    next_video = Queue.get_next_video(video_queue, current_video_id)

    case next_video do
      nil -> {:noreply, socket}
      video ->
        %{slug: slug} = socket.assigns
        %{video_id: video_id} = video
        player = Player.update(player, %{video_id: video_id, time: 0, state: "playing", previous_id: video.previous, next_id: video.next})
        player_controls = Player.get_controls_state(player)

        :ok = Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          "room:" <> slug,
          {:player_signal_play_next, %{player: player, player_controls: player_controls}}
        )

        {:noreply, socket}
    end
  end

  def handle_event("player_signal_play_previous", _params, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    %{video_id: current_video_id} = player
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    previous_video = Queue.get_previous_video(video_queue, current_video_id)

    case previous_video do
      nil -> {:noreply, socket}
      video ->
        %{slug: slug} = socket.assigns
        %{video_id: video_id} = video
        player = Player.update(player, %{video_id: video_id, time: 0, state: "playing", previous_id: video.previous, next_id: video.next})
        player_controls = Player.get_controls_state(player)

        :ok = Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          "room:" <> slug,
          {:player_signal_play_previous, %{player: player, player_controls: player_controls}}
        )

        {:noreply, socket}
    end
  end

#
# ===========================================================================

  @impl true
  def handle_event("remove_track", params, socket) do
    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:remove_track, %{video_id: params["video_id"]}}
    )
    {:noreply, socket}
  end

  @impl true
  def handle_event("player_signal_sort_video", %{"from" => from, "to" => to}, socket) do
    %{
      player: player,
      video_queue: video_queue,
      video_queue_controls: video_queue_controls
    } = socket.assigns

    {video, queue} = Queue.take_from_indexed_queue(video_queue, from)

    video_queue = queue
    |> List.insert_at(to, video)
    |> Enum.with_index()
    |> Queue.link_tracks(from, to)

    {%{previous: previous, next: next}, _} = Enum.find(video_queue, fn {v,_} ->
      v.video_id == player.video_id
    end)

    player = Player.update(player, %{previous_id: previous, next_id: next})

    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:player_signal_sort_video, %{
        player: player,
        player_controls: Player.get_controls_state(player),
        video_queue: video_queue,
        video_queue_controls: Queue.mark_as_unsaved(video_queue_controls),
        sorted_video_position: to+1}}
    )
    {:noreply, socket}
  end

  @impl true
  def handle_event("player_signal_play_by_id", params, socket) do
    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:player_signal_play_by_id, %{video_id: params["video_id"]}}
    )
    {:noreply, socket}
  end

  @impl true
  def handle_event("volume_level_changed", volume_level, socket) do
    %{slug: slug, user: %{uuid: uuid}} = socket.assigns
    volume_icon = case volume_level do
      l when l > 70 -> "fa-volume-up"
      l when l > 30 -> "fa-volume-down"
      l when l > 0 -> "fa-volume-off"
      l when l == 0 -> "fa-volume-mute"
    end

    :ok = Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> slug,
      {:volume_level_changed, %{uuid: uuid, volume_level: volume_level, volume_icon: volume_icon}}
    )
    {:reply, %{level: volume_level},
      socket
      |> assign(:volume_controls, %{volume_level: volume_level})}
  end

  @impl true
  def handle_event(
    "search",
    %{"search_field" => %{"query" => query}},
    %{assigns: %{video_queue: video_queue}} = socket
  ) do
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    opts = [maxResults: 10]
    {:ok, search_result, _pagination_options} = Tubex.Video.search_by_query(query, opts)
    search_result = Enum.map(search_result, fn search ->
      video = Video.from_tubex_video(search)
      Video.update(video, %{is_queued: Queue.is_queued(video, video_queue)}) end)
    {:noreply,
      socket
      |> assign(:search_result, search_result)}
  end

  @impl true
  def handle_event("add_to_queue", selected_video, socket) do
    %{assigns: %{search_result: search_result, video_queue: video_queue, video_queue_controls: video_queue_controls}} = socket
    selected_video = Enum.find(search_result, fn search -> search.video_id == selected_video["video_id"] end)
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    updated_video_queue = Queue.add_to_queue(video_queue, selected_video)
    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:add_to_queue, %{
        updated_video_queue: updated_video_queue,
        video_queue_controls: Queue.mark_as_unsaved(video_queue_controls),
        added_video_position: length(updated_video_queue)}}
    )
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_queue", _params, socket) do
    %{assigns: %{room: room, slug: slug, video_queue: video_queue, video_queue_controls: video_queue_controls}} = socket
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    {:ok, _room} = Organizer.update_room(room, %{queue: video_queue})

    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> slug,
      {:save_queue, %{video_queue_controls: Queue.mark_as_saved(video_queue_controls)}}
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

  @impl true
  def handle_event(
    "new_message",
    %{"submit" => %{"message" => message}},
    socket
  ) do
    socket = socket |> assign(:new_message, "")
    case String.trim(message) do
      "" ->
        {:noreply, socket}
      _ ->
        %{messages: messages, slug: slug, user: %{uuid: uuid}} = socket.assigns
        message = Chat.create_message(:new, %{message: message, uuid: uuid})
        messages = messages ++ [message]
        Phoenix.PubSub.broadcast_from(
          LiveDj.PubSub,
          self(),
          "room:" <> slug,
          {:receive_messages, %{messages: messages}}
        )
        {:noreply,
          socket
          |> assign(:messages, messages)
          |> push_event("receive_new_message", %{})}
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
            {:ok, updated_room} = Organizer.update_room(room, %{video_tracker: p.uuid})
            updated_room
        end
    end
  end

  defp create_connected_user do
    %ConnectedUser{uuid: UUID.uuid4()}
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

  defp fake_search_data(video_queue) do
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
    Enum.map(search_data, fn search ->
      video = Video.from_tubex_video(search)
      Video.update(video, %{is_queued: Queue.is_queued(video, video_queue)}) end)
  end
end
