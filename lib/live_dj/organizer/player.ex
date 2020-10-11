defmodule LiveDj.Organizer.Player do

  alias LiveDj.Organizer.Video

  def get_initial_state do
    %{state: "paused", video_id: "", time: 0}
  end

  def get_controls_state(%{video_id: "", state: "paused"}) do
    %{play_button_state: "disabled", pause_button_state: "disabled"}
  end

  def get_controls_state(%{video_id: _, state: "paused"}) do
    %{play_button_state: "", pause_button_state: "disabled"}
  end

  def get_controls_state(%{video_id: _, state: "playing"}) do
    %{play_button_state: "disabled", pause_button_state: ""}
  end

  def update(player, props) do
    Map.merge(player, props)
  end

  def create_response(player) do
    %{
      shouldPlay: should_play(player),
      videoId: player.video_id,
      time: player.time
    }
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

  defp should_play(player) do
    player.state == "playing" && player.video_id != ""
  end
end
