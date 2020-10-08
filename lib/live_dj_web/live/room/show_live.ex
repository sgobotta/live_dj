defmodule LiveDjWeb.Room.ShowLive do
  @moduledoc """
  A LiveView for creating and joining rooms.
  """

  use LiveDjWeb, :live_view

  alias LiveDj.Organizer
  alias LiveDj.ConnectedUser
  alias LiveDjWeb.Presence
  alias Phoenix.Socket.Broadcast

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    user = create_connected_user()
    room = Organizer.get_room(slug)
    Phoenix.PubSub.subscribe(LiveDj.PubSub, "room:" <> slug)
    Organizer.subscribe(:request_player_sync, slug)

    {:ok, _} = Presence.track(self(), "room:" <> slug, user.uuid, %{})

    case room do
      nil ->
        {:ok,
          socket
          |> put_flash(:error, "That room does not exist.")
          |> push_redirect(to: Routes.new_path(socket, :new))
        }
      room ->
        {:ok,
          socket
          |> assign(:user, user)
          |> assign(:slug, slug)
          |> assign(:connected_users, [])
          |> assign(:video_queue, [])
          |> assign(:search_result, [])
          |> assign(:current_video, %{video_id: "", time: 0 })
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

  def handle_info({:refresh_queue, %{selected_video: selected_video}}, socket) do
    video_queue = socket.assigns.video_queue ++ [selected_video]
    search_result = Enum.map(socket.assigns.search_result, fn search ->
      mark_as_queued(search, video_queue)
    end)

    {:noreply,
     socket
     |> assign(:search_result, search_result)
     |> assign(:video_queue, video_queue)}
  end

  def handle_info({:request_player_sync, params}, socket) do
    Organizer.unsubscribe(:request_player_sync, socket.assigns.slug)

    {:noreply,
     socket
     |> assign(:video_queue, params)
     |> push_event("receive_current_video", %{params: params})}
  end

  def handle_info({:request_initial_state, _params}, socket) do
    :ok = Phoenix.PubSub.broadcast_from(
      LiveDj.PubSub,
      self(),
      "room:" <> socket.assigns.slug <> ":request_initial_state",
      {:receive_initial_state, %{current_queue: socket.assigns.video_queue}}
    )

    {:noreply, socket}
  end

  def handle_info({:receive_initial_state, %{current_queue: current_queue}}, socket) do
    Organizer.unsubscribe(:request_initial_state, socket.assigns.slug)

    {:noreply,
      socket
      |> assign(:video_queue, current_queue)
    }
  end

  @impl true
  def handle_event("player-is-ready", _, socket) do
    current_video = socket.assigns.current_video
    message = %{
      shouldPlay: current_video.video_id != "",
      startTime: current_video.time,
      videoId: current_video.video_id
    }

    Organizer.subscribe(:request_initial_state, socket.assigns.slug)

    :ok = Phoenix.PubSub.broadcast_from(
      LiveDj.PubSub,
      self(),
      "room:" <> socket.assigns.slug,
      {:request_initial_state, %{}}
    )

    {:reply, message, socket}
  end

  @impl true
  def handle_event("search", %{"search_field" => %{"query" => query}}, socket) do
    opts = [maxResults: 3]
    {:ok, videos, _pagination_options} = Tubex.Video.search_by_query(query, opts)

    search_result = Enum.map(videos, fn video ->
      mark_as_queued(video, socket.assigns.video_queue)
    end)
    {:noreply, assign(socket, :search_result, search_result)}
  end

  @impl true
  def handle_event("add_to_queue", selected_video, socket) do
    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:refresh_queue, %{selected_video: selected_video}}
    )
    {:noreply, socket}
  end

  @impl true
  def handle_event("request_player_sync", _params, socket) do
    IO.inspect("SOCKET")
    # IO.inspect(socket.assigns)
    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug <> ":request_player_sync",
      {:request_player_sync, socket.assigns.video_queue})
    {:noreply, socket}
  end

  @impl true
  def handle_event("video-time-sync", current_time, socket) do
    slug = socket.assigns.room.slug
    room = Organizer.get_room(slug)
    current_user = socket.assigns.user.uuid

    case current_user == room.video_tracker do
      true ->
        {:ok, _updated_room} = Organizer.update_room(room, %{video_time: current_time})
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
          presences ->
            first_presence = hd presences
            {:ok, updated_room} = Organizer.update_room(room, %{video_tracker: first_presence})
            updated_room
        end
    end
  end

  defp create_connected_user do
    %ConnectedUser{uuid: UUID.uuid4()}
  end

  defp is_queued(video, video_queue) do
    Enum.any?(video_queue, fn qv -> qv["video_id"] == video.video_id end)
  end

  defp mark_as_queued(video, video_queue) do
    video = %{
      title: video.title,
      thumbnails: video.thumbnails,
      channel_title: video.channel_title,
      description: video.description,
      video_id: video.video_id,
      is_queued: ""
    }
    case is_queued(video, video_queue) do
      true -> Map.merge(video, %{is_queued: "disabled"})
      false -> video
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
    [
      %Tubex.Video{
        channel_id: "UCtWuB1D_E3mcyYThA9iKggQ",
        channel_title: "Vulf",
        description: "VULFPECK /// Wait for the Moment (feat. Antwaun Stanley) buy on bandcamp → https://vulfpeck.bandcamp.com Antwaun Stanley — vocals Jack Stratton ...",
        etag: nil,
        playlist_id: nil,
        published_at: "2013-08-06T07:24:31Z",
        thumbnails: %{
          "default" => %{
            "height" => 90,
            "url" => "https://i.ytimg.com/vi/r4G0nbpLySI/default.jpg",
            "width" => 120
          },
          "high" => %{
            "height" => 360,
            "url" => "https://i.ytimg.com/vi/r4G0nbpLySI/hqdefault.jpg",
            "width" => 480
          },
          "medium" => %{
            "height" => 180,
            "url" => "https://i.ytimg.com/vi/r4G0nbpLySI/mqdefault.jpg",
            "width" => 320
          }
        },
        title: "VULFPECK /// Wait for the Moment",
        video_id: "r4G0nbpLySI"
      },
      %Tubex.Video{
        channel_id: "UC-2JUs_G21BrJ0efehwGkUw",
        channel_title: "Scary Pockets",
        description: "Subscribe to stories: https://www.youtube.com/channel/UC-yUK_2HT9rxQSsweAjjNiA Spotify: https://tinyurl.com/rooupcg iTunes: https://tinyurl.com/wdgfsd9 Ok, ...",
        etag: nil,
        playlist_id: nil,
        published_at: "2019-11-28T16:00:14Z",
        thumbnails: %{
          "default" => %{
            "height" => 90,
            "url" => "https://i.ytimg.com/vi/myzNf5kW1kQ/default.jpg",
            "width" => 120
          },
          "high" => %{
            "height" => 360,
            "url" => "https://i.ytimg.com/vi/myzNf5kW1kQ/hqdefault.jpg",
            "width" => 480
          },
          "medium" => %{
            "height" => 180,
            "url" => "https://i.ytimg.com/vi/myzNf5kW1kQ/mqdefault.jpg",
            "width" => 320
          }
        },
        title: "wait for the moment | vulfpeck | ‘stories’ acoustic cover ft. hunter elizabeth",
        video_id: "myzNf5kW1kQ"
      },
      %Tubex.Video{
        channel_id: "UCWuBpAte4YHm_oELpzoM2qg",
        channel_title: "Vulfpeck - Topic",
        description: "Provided to YouTube by TuneCore Wait for the Moment (Live at Madison Square Garden) · Vulfpeck · Antwaun Stanley Live at Madison Square Garden ℗ 2019 ...",
        etag: nil,
        playlist_id: nil,
        published_at: "2019-12-09T10:00:22Z",
        thumbnails: %{
          "default" => %{
            "height" => 90,
            "url" => "https://i.ytimg.com/vi/ZxjrWgUn0Wo/default.jpg",
            "width" => 120
          },
          "high" => %{
            "height" => 360,
            "url" => "https://i.ytimg.com/vi/ZxjrWgUn0Wo/hqdefault.jpg",
            "width" => 480
          },
          "medium" => %{
            "height" => 180,
            "url" => "https://i.ytimg.com/vi/ZxjrWgUn0Wo/mqdefault.jpg",
            "width" => 320
          }
        },
        title: "Wait for the Moment (Live at Madison Square Garden)",
        video_id: "ZxjrWgUn0Wo"
      }
    ]
  end
end
