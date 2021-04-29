defmodule LiveDj.Organizer.PlaylistVideoQueueItem do
  alias LiveDj.Organizer.PlaylistVideoQueueItem

  @enforce_keys [
    :channel_title,
    :description,
    :img_height,
    :img_url,
    :img_width,
    :next,
    :previous,
    :title,
    :video_id
  ]

  defstruct channel_title: nil,
            description: nil,
            img_height: nil,
            img_url: nil,
            img_width: nil,
            next: nil,
            previous: nil,
            title: nil,
            video_id: nil

  defp get_video_id(video) do
    case video do
      nil -> ""
      video -> video.video_id
    end
  end

  def create(playlist_video) do
    %PlaylistVideoQueueItem{
      channel_title: playlist_video.video.channel_title,
      description: playlist_video.video.description,
      img_height: playlist_video.video.img_height,
      img_url: playlist_video.video.img_url,
      img_width: playlist_video.video.img_width,
      title: playlist_video.video.title,
      video_id: playlist_video.video.video_id,
      previous: get_video_id(playlist_video.previous_video),
      next: get_video_id(playlist_video.next_video)
    }
  end
end

defmodule LiveDj.Organizer.Queue do
  alias LiveDj.Collections
  alias LiveDj.Organizer.{PlaylistVideoQueueItem, QueueItem}

  def from_playlist(playlist_id) do
    Collections.list_playlists_videos_by_id(playlist_id)
    |> Enum.map(fn playlist_video ->
      Collections.preload_playlist_video(playlist_video, [:next_video, :previous_video, :video])
      |> PlaylistVideoQueueItem.create()
      |> QueueItem.from_playlist_video_queue_item()
    end)
  end

  def get_initial_controls do
    %{is_save_enabled: false}
  end

  def mark_as_saved(queue_controls) do
    Map.merge(queue_controls, %{is_save_enabled: false})
  end

  def mark_as_unsaved(queue_controls) do
    Map.merge(queue_controls, %{is_save_enabled: true})
  end

  def is_queued(video, queue) do
    Enum.any?(queue, fn qv -> qv.video_id == video.video_id end)
  end

  def add_to_queue(queue, video) do
    case queue do
      [] ->
        [video]

      [v] ->
        [
          QueueItem.update(v, %{next: video.video_id})
          | [QueueItem.update(video, %{previous: v.video_id})]
        ]

      [v | vs] ->
        videos = Enum.drop(vs, -1)
        last_video = QueueItem.update(List.last(vs), %{next: video.video_id})
        new_video = QueueItem.update(video, %{previous: last_video.video_id})
        [v | videos ++ [last_video, new_video]]
    end
  end

  def remove_video_by_id(queue, video_id) do
    video = get_video_by_id(queue, video_id)
    queue = Enum.filter(queue, fn video -> video.video_id != video_id end)

    Enum.map(queue, fn v ->
      case v.next == video.video_id do
        true ->
          QueueItem.update(v, %{next: video.next})

        false ->
          case v.previous == video.video_id do
            true -> QueueItem.update(v, %{previous: video.previous})
            false -> v
          end
      end
    end)
  end

  def take_from_indexed_queue(queue, index) do
    Enum.reduce(queue, {nil, []}, fn {v, i}, {e, q} ->
      case i do
        ^index -> {v, q}
        _ -> {e, q ++ [v]}
      end
    end)
  end

  def link_by_prop(queue, prop, from, to) do
    {_, queue} =
      Enum.reduce(queue, {"", []}, fn {v, i}, {link_id, vs_acc} ->
        video =
          case i do
            ^from -> QueueItem.update(v, %{prop => link_id})
            ^to -> QueueItem.update(v, %{prop => link_id})
            i when from - 1 == i -> QueueItem.update(v, %{prop => link_id})
            i when from + 1 == i -> QueueItem.update(v, %{prop => link_id})
            i when to - 1 == i -> QueueItem.update(v, %{prop => link_id})
            i when to + 1 == i -> QueueItem.update(v, %{prop => link_id})
            _ -> v
          end

        {video.video_id, vs_acc ++ [{video, i}]}
      end)

    queue
  end

  def link_tracks(queue, from, to) do
    queue = link_by_prop(queue, :previous, from, to)

    link_by_prop(Enum.reverse(queue), :next, from, to)
    |> Enum.reverse()
  end

  defp get_video(queue, prop, video_id) do
    Enum.find(queue, fn video -> Map.get(video, prop) == video_id end)
  end

  def get_video_by_id(queue, video_id) do
    get_video(queue, :video_id, video_id)
  end

  def get_next_video(queue, previous_video_id) do
    get_video(queue, :previous, previous_video_id)
  end

  def get_previous_video(queue, next_video_id) do
    get_video(queue, :next, next_video_id)
  end
end
