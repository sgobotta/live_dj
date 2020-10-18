defmodule LiveDj.Organizer.Player do

  def get_initial_state do
    %{state: "paused", video_id: "", time: 0}
  end

  def get_controls_state(%{video_id: "", state: _}) do
    %{play_button_state: "disabled", pause_button_state: "disabled"}
  end

  def get_controls_state(%{video_id: _, state: "paused"}) do
    %{play_button_state: "", pause_button_state: "disabled"}
  end

  def get_controls_state(%{video_id: _, state: "stopped"}) do
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

  defp should_play(player) do
    player.state == "playing" && player.video_id != ""
  end
end
