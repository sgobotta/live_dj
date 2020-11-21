defmodule LiveDjWeb.Components.PlayerControls do
  @moduledoc """
  Responsible for displaying the player controls
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Organizer.Player
  alias LiveDj.Organizer.Queue


  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end

# ===========================================================================
#
# Very similar functions, refactor if not used for a specific task
#

  def handle_event("player_signal_play_previous", _params, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    %{video_id: current_video_id} = player
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    previous_video = Queue.get_previous_video(video_queue, current_video_id)

    case previous_video do
      nil -> {:noreply, socket}
      video ->
        %{slug: slug} = socket.assigns
        %{video_id: video_id} = video
        player = Player.update(player, %{video_id: video_id, time: 0, state: "playing", previous_id: video.previous, next_id: video.next})
        player_controls = Player.get_controls_state(player)

        :ok = Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          "room:" <> slug,
          {:player_signal_play_previous, %{player: player, player_controls: player_controls}}
        )

        {:noreply, socket}
    end
  end

  def handle_event("player_signal_play_next", _params, socket) do
    %{video_queue: video_queue, player: player} = socket.assigns
    %{video_id: current_video_id} = player
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    next_video = Queue.get_next_video(video_queue, current_video_id)

    case next_video do
      nil -> {:noreply, socket}
      video ->
        %{slug: slug} = socket.assigns
        %{video_id: video_id} = video
        player = Player.update(player, %{video_id: video_id, time: 0, state: "playing", previous_id: video.previous, next_id: video.next})
        player_controls = Player.get_controls_state(player)

        :ok = Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          "room:" <> slug,
          {:player_signal_play_next, %{player: player, player_controls: player_controls}}
        )

        {:noreply, socket}
    end
  end

#
# ===========================================================================
end
