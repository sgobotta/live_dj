defmodule LivedjWeb.PlayerControlsLive do
  use LivedjWeb, {:live_view, layout: false}

  alias Livedj.Sessions
  alias Livedj.Sessions.{Player, Room}

  @on_play_click "on_play_click"
  @on_pause_click "on_pause_click"

  def mount(params, _session, socket) do
    case connected?(socket) do
      true ->
        %Room{id: room_id} = room = Sessions.get_room!(params["id"])
        {:ok, :joined} = Sessions.join_player(room_id)

        {:ok,
         assign(socket,
           player_controls_id: "player-controls-#{Ecto.UUID.generate()}",
           start_time_tracker_id: "player-controls-start-time-tracker",
           end_time_tracker_id: "player-controls-end-time-tracker",
           time_slider_id: "player-controls-time-slider",
           volume_control_id: "volume-control-#{room_id}",
           fullscreen_control_id: "fullscreen-control-#{room_id}",
           add_video_control_id: "add-video-control-#{room_id}",
           layout: false,
           player: nil,
           room: room
         )}

      false ->
        {:ok,
         assign(socket,
           player: nil,
           start_time_tracker_id: nil,
           end_time_tracker_id: nil,
           time_slider_id: nil
         )}
    end
  end

  def update(_assigns, socket) do
    {:ok, socket}
  end

  def handle_event(@on_play_click, _params, socket) do
    {:noreply,
     push_event(socket, "request_current_time", %{
       callback_event: "on_player_play"
     })}
  end

  def handle_event(@on_pause_click, _params, socket) do
    {:noreply,
     push_event(socket, "request_current_time", %{
       callback_event: "on_player_pause"
     })}
  end

  @impl true
  def handle_event("previous", _params, socket) do
    Sessions.previous_track(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("next", _params, socket) do
    Sessions.next_track(socket.assigns.room.id)
    {:noreply, socket}
  end

  # ----------------------------------------------------------------------------
  # Player event handling
  #

  def handle_info(
        {:player_joined, _room_id, %{player: %Sessions.Player{} = player}},
        socket
      ) do
    JS.transition({"ease-out duration-1000", "opacity-0", "opacity-100"},
      to: "##{socket.assigns.player_controls_id}"
    )

    {:noreply, assign_player(socket, player)}
  end

  def handle_info(
        {:player_state_changed, room_id, %Player{}},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_info(
        {:player_load_media, _room_id, %Sessions.Player{} = player},
        socket
      ) do
    {:noreply, assign_player(socket, player)}
  end

  def handle_info({:player_play, _room_id, %Player{} = player}, socket) do
    {:noreply, assign_player(socket, player)}
  end

  def handle_info({:player_pause, _room_id, %Player{} = player}, socket) do
    {:noreply, assign_player(socket, player)}
  end

  @spec assign_player(Phoenix.LiveView.Socket.t(), Sessions.Player.t()) ::
          Phoenix.LiveView.Socket.t()
  defp assign_player(socket, player), do: assign(socket, :player, player)

  defp on_play_click_event, do: @on_play_click
  defp on_pause_click_event, do: @on_pause_click

  defp render_default_seek_bar_value, do: "0:00"

  defp media_loaded?(""), do: false
  defp media_loaded?(_media_id), do: true
end
