defmodule LiveDjWeb.Components.QueueControls do
  @moduledoc """
  Responsible for displaying the queue controls
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Collections
  alias LiveDj.Organizer
  alias LiveDj.Organizer.Queue

  @impl true
  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end

  @impl true
  def handle_event("save_queue", _params, %{assigns: assigns} = socket) do
    %{
      room: room,
      slug: slug,
      video_queue: video_queue,
      video_queue_controls: video_queue_controls
    } = assigns
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    {:ok, _room} = Organizer.update_room(room, %{queue: video_queue})
    # Recreates a playlists_videos relationships
    # FIXME: Move to a proper context
    # FIXME: find a way to update only the affected video
    updated_playlists_videos = Enum.map(Enum.with_index(video_queue), fn {video, index} ->
      Collections.cast_playlist_video(
        Map.merge(video, %{position: index, added_by_user_id: video.added_by.user_id}), room.playlist_id
      )
    end)
    |> Collections.create_or_update_playlists_videos()
    # Removes orphan playlist_video relationships
    Collections.list_playlists_videos_by_id(room.playlist_id)
    |> Enum.filter(fn opv -> !Enum.member?(Enum.map(updated_playlists_videos, fn upv -> upv.id end), opv.id) end)
    |> Enum.map(fn orphan_playlist_video ->
      {:ok, _result} = Collections.delete_playlist_video(orphan_playlist_video)
    end)

    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> slug,
      {:save_queue,
        %{video_queue_controls: Queue.mark_as_saved(video_queue_controls)}}
    )

    {:noreply, socket}
  end
end
