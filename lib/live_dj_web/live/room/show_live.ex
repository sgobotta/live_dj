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
    Phoenix.PubSub.subscribe(LiveDj.PubSub, "room:" <> slug)
    Organizer.subscribe(:request_queue, slug)

    {:ok, _} = Presence.track(self(), "room:" <> slug, user.uuid, %{})

    case Organizer.get_room(slug) do
      nil ->
        {:ok,
          socket
          |> put_flash(:error, "That room does not exist.")
          |> push_redirect(to: Routes.new_path(socket, :new))
        }
      room ->
        {:ok,
          socket
          |> assign(:room, room)
          |> assign(:user, user)
          |> assign(:slug, slug)
          |> assign(:connected_users, [])
          |> assign(:video_queue, fake_video_queue())
          |> assign(:search_result, [])
        }
    end
  end

  @impl true
  def handle_info(
    %Broadcast{event: "presence_diff", payload: payload},
    %{assigns: %{user: user}} = socket
  ) do

    case Organizer.is_connected(user, payload) do
      false ->
        {:noreply,
          socket
          |> assign(:connected_users, list_present(socket))
          |> push_event("presence-changed", %{ presence: list_present(socket) })
        }
      true ->
        {:noreply,
          socket
          |> assign(:connected_users, list_present(socket))
        }
    end
  end

  def handle_info({:queue, params}, socket) do
    {:noreply,
     socket
     |> assign(:video_queue, params)
     |> push_event("queue", %{params: params})}
  end

  def handle_info({:cue, params}, socket) do
    IO.inspect("called cue")
    {:noreply,
     socket
     |> push_event("cue", %{params: params})}
  end

  def handle_info({:sync_queue, params}, socket) do
    Organizer.unsubscribe(:request_queue, socket.assigns.slug)
    {:noreply,
     socket
     |> assign(:video_queue, params)
     |> push_event("queue", %{params: params})}
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
  def handle_event("queue", params, socket) do
    video_queue = socket.assigns.video_queue ++ [params]
    search_result = Enum.map(socket.assigns.search_result, fn search ->
      mark_as_queued(search, video_queue)
    end)
    Phoenix.PubSub.broadcast(LiveDj.PubSub, "room:" <> socket.assigns.slug, {:queue, video_queue })
    {:noreply,
      socket
      |> assign(:search_result, search_result)
    }
  end

  @impl true
  def handle_event("cue", params, socket) do
    Phoenix.PubSub.broadcast(LiveDj.PubSub, "room:" <> socket.assigns.slug, {:cue, params })
    {:noreply, socket}
  end

  @impl true
  def handle_event("sync_queue", _params, socket) do
    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug <> ":request-queue",
      {:sync_queue, socket.assigns.video_queue
    })
    {:noreply, socket}
  end

  defp list_present(socket) do
    Presence.list("room:" <> socket.assigns.slug)
    |> Enum.filter(fn {k, _} -> k !== socket.assigns.user.uuid end)
    |> Enum.map(fn {k, _} -> k end)
  end

  defp create_connected_user do
    %ConnectedUser{uuid: UUID.uuid4()}
  end

  defp is_queued(video, video_queue) do
    Enum.any?(video_queue, fn qv -> qv["video_id"] == video.video_id end)
  end

  defp mark_as_queued(video, video_queue) do
    case is_queued(video, video_queue) do
      true -> %{
        title: video.title,
        thumbnails: video.thumbnails,
        channel_title: video.channel_title,
        description: video.description,
        video_id: video.video_id,
        is_queued: "disabled"
      }
      false -> %{
        title: video.title,
        thumbnails: video.thumbnails,
        channel_title: video.channel_title,
        description: video.description,
        video_id: video.video_id,
        is_queued: ""
      }
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
