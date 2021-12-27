defmodule LiveDj.Organizer.Player do
  @moduledoc false

  def get_initial_state do
    %{state: "stopped", video_id: "", time: 0, previous_id: "", next_id: ""}
  end

  def get_controls_state(%{video_id: "", state: _}) do
    %{
      play_button_state: "disabled",
      pause_button_state: "disabled",
      previous_button_state: "disabled",
      next_button_state: "disabled"
    }
  end

  def get_controls_state(%{video_id: _, state: "paused", previous_id: "", next_id: ""}) do
    %{
      play_button_state: "",
      pause_button_state: "disabled",
      previous_button_state: "disabled",
      next_button_state: "disabled"
    }
  end

  def get_controls_state(%{video_id: _, state: "paused", previous_id: _, next_id: ""}) do
    %{
      play_button_state: "",
      pause_button_state: "disabled",
      previous_button_state: "",
      next_button_state: "disabled"
    }
  end

  def get_controls_state(%{video_id: _, state: "paused", previous_id: "", next_id: _}) do
    %{
      play_button_state: "",
      pause_button_state: "disabled",
      previous_button_state: "disabled",
      next_button_state: ""
    }
  end

  def get_controls_state(%{video_id: _, state: "paused", previous_id: _, next_id: _}) do
    %{
      play_button_state: "",
      pause_button_state: "disabled",
      previous_button_state: "",
      next_button_state: ""
    }
  end

  def get_controls_state(%{video_id: _, state: "stopped", previous_id: "", next_id: ""}) do
    %{
      play_button_state: "",
      pause_button_state: "disabled",
      previous_button_state: "disabled",
      next_button_state: "disabled"
    }
  end

  def get_controls_state(%{video_id: _, state: "stopped", previous_id: "", next_id: _}) do
    %{
      play_button_state: "",
      pause_button_state: "disabled",
      previous_button_state: "disabled",
      next_button_state: ""
    }
  end

  def get_controls_state(%{video_id: _, state: "stopped", previous_id: _, next_id: ""}) do
    %{
      play_button_state: "",
      pause_button_state: "disabled",
      previous_button_state: "",
      next_button_state: "disabled"
    }
  end

  def get_controls_state(%{video_id: _, state: "stopped", previous_id: _, next_id: _}) do
    %{
      play_button_state: "",
      pause_button_state: "disabled",
      previous_button_state: "",
      next_button_state: ""
    }
  end

  def get_controls_state(%{video_id: _, state: "playing", previous_id: "", next_id: ""}) do
    %{
      play_button_state: "disabled",
      pause_button_state: "",
      previous_button_state: "disabled",
      next_button_state: "disabled"
    }
  end

  def get_controls_state(%{video_id: _, state: "playing", previous_id: "", next_id: _}) do
    %{
      play_button_state: "disabled",
      pause_button_state: "",
      previous_button_state: "disabled",
      next_button_state: ""
    }
  end

  def get_controls_state(%{video_id: _, state: "playing", previous_id: _, next_id: ""}) do
    %{
      play_button_state: "disabled",
      pause_button_state: "",
      previous_button_state: "",
      next_button_state: "disabled"
    }
  end

  def get_controls_state(%{video_id: _, state: "playing", previous_id: _, next_id: _}) do
    %{
      play_button_state: "disabled",
      pause_button_state: "",
      previous_button_state: "",
      next_button_state: ""
    }
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
  @moduledoc false

  def get_initial_state do
    %{
      volume_level: 100,
      is_muted: false,
      volume_icon: "speaker-4"
    }
  end

  def get_volume_icon(volume_level) do
    case volume_level do
      l when l > 70 -> "speaker-4"
      l when l > 40 -> "speaker-3"
      l when l > 10 -> "speaker-2"
      l when l > 0 -> "speaker-1"
      l when l == 0 -> "speaker-0"
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
