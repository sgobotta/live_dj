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
          |> assign(:search_result, fake_search_data())
        }
    end
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply,
      socket
      |> assign(:connected_users, list_present(socket))}
  end

  @impl true
  def handle_event("search", %{"search_field" => %{"query" => query}}, socket) do
    opts = [maxResults: 3]
    {:ok, videos, _pagination_options} = Tubex.Video.search_by_query(query, opts)
    {:noreply, assign(socket, :search_result, videos)}
  end

  defp list_present(socket) do
    Presence.list("room:" <> socket.assigns.slug)
    |> Enum.map(fn {k, _} -> k end) # Phoenix Presence provides nice metadata, but we don't need it.
  end

  defp create_connected_user do
    %ConnectedUser{uuid: UUID.uuid4()}
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
