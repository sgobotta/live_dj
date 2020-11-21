defmodule LiveDj.Organizer.Player do

  def get_initial_state do
    %{state: "stopped", video_id: "", time: 0, previous_id: "", next_id: ""}
  end

  def get_controls_state(%{video_id: "", state: _}) do
    %{play_button_state: "disabled", pause_button_state: "disabled", previous_button_state: "disabled", next_button_state: "disabled"}
  end

  def get_controls_state(%{video_id: _, state: "paused", previous_id: "", next_id: ""}) do
    %{play_button_state: "", pause_button_state: "disabled", previous_button_state: "disabled", next_button_state: "disabled"}
  end

  def get_controls_state(%{video_id: _, state: "paused", previous_id: _, next_id: ""}) do
    %{play_button_state: "", pause_button_state: "disabled", previous_button_state: "", next_button_state: "disabled"}
  end

  def get_controls_state(%{video_id: _, state: "paused", previous_id: "", next_id: _}) do
    %{play_button_state: "", pause_button_state: "disabled", previous_button_state: "disabled", next_button_state: ""}
  end

  def get_controls_state(%{video_id: _, state: "paused", previous_id: _, next_id: _}) do
    %{play_button_state: "", pause_button_state: "disabled", previous_button_state: "", next_button_state: ""}
  end

  def get_controls_state(%{video_id: _, state: "stopped", previous_id: "", next_id: ""}) do
    %{play_button_state: "", pause_button_state: "disabled", previous_button_state: "disabled", next_button_state: "disabled"}
  end

  def get_controls_state(%{video_id: _, state: "stopped", previous_id: "", next_id: _}) do
    %{play_button_state: "", pause_button_state: "disabled", previous_button_state: "disabled", next_button_state: ""}
  end

  def get_controls_state(%{video_id: _, state: "stopped", previous_id: _, next_id: ""}) do
    %{play_button_state: "", pause_button_state: "disabled", previous_button_state: "", next_button_state: "disabled"}
  end

  def get_controls_state(%{video_id: _, state: "stopped", previous_id: _, next_id: _}) do
    %{play_button_state: "", pause_button_state: "disabled", previous_button_state: "", next_button_state: ""}
  end

  def get_controls_state(%{video_id: _, state: "playing", previous_id: "", next_id: _}) do
    %{play_button_state: "disabled", pause_button_state: "", previous_button_state: "disabled", next_button_state: ""}
  end

  def get_controls_state(%{video_id: _, state: "playing", previous_id: _, next_id: ""}) do
    %{play_button_state: "disabled", pause_button_state: "", previous_button_state: "", next_button_state: "disabled"}
  end

  def get_controls_state(%{video_id: _, state: "playing", previous_id: _, next_id: _}) do
    %{play_button_state: "disabled", pause_button_state: "", previous_button_state: "", next_button_state: ""}
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

defmodule LiveDj.Organizer.VolumeControls do

  def get_volume_icon(volume_level) do
    case volume_level do
      l when l > 70 -> "fa-volume-up"
      l when l > 30 -> "fa-volume-down"
      l when l > 0 -> "fa-volume-off"
      l when l == 0 -> "fa-volume-mute"
    end
  end

  def get_state_by_level(volume_level) do
    case volume_level do
      0 -> true
      _ -> false
    end
  end

  def update(controls, props) do
    Map.merge(controls, props)
  end
end
