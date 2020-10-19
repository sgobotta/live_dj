defmodule LiveDj.Organizer.Queue do

  alias LiveDj.Organizer.Video

  def get_initial_controls do
    %{is_save_enabled: false}
  end

  def mark_as_saved(queue_controls) do
    Map.merge(queue_controls, %{is_save_enabled: false})
  end

  def mark_as_unsaved(queue_controls) do
    Map.merge(queue_controls, %{is_save_enabled: true})
  end

  def add_to_queue(queue, video) do
    case queue do
      []  -> [video]
      [v] -> [Video.update(v, %{next: video.video_id}) | [Video.update(video, %{previous: v.video_id})]]
      [v|vs] ->
        videos = Enum.drop(vs, -1)
        last_video = Video.update(List.last(vs), %{next: video.video_id})
        new_video = Video.update(video, %{previous: last_video.video_id})
        [v | videos ++ [last_video, new_video]]
    end
  end

  def get_video_by_id(video_queue, video_id) do
    Enum.find(video_queue, fn video -> video.video_id == video_id end)
  end

  def get_next_video(video_queue, current_video_id) do
    Enum.find(video_queue, fn video -> video.previous == current_video_id end)
  end

  def get_previous_video(video_queue, current_video_id) do
    Enum.find(video_queue, fn video -> video.next == current_video_id end)
  end
end
