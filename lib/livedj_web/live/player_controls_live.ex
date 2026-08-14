defmodule LivedjWeb.PlayerControlsLive do
  use LivedjWeb, {:live_view, layout: {LivedjWeb.Layouts, :flash}}

  alias Livedj.Sessions
  alias Livedj.Sessions.{Channels, Player, Room}

  @on_play_click "on_play_click"
  @on_pause_click "on_pause_click"

  def mount(
        :not_mounted_at_router,
        %{
          "id" => room_id,
          "user_id" => user_id,
          "display_name" => display_name
        },
        socket
      ) do
    case connected?(socket) do
      true ->
        %Room{id: ^room_id} = room = Sessions.get_room!(room_id)
        {:ok, :joined} = Sessions.join_player(room_id)
        :ok = Channels.subscribe_chat_topic(room_id)

        connect_params = get_connect_params(socket)

        volume_level =
          String.to_integer(connect_params["_volume_level"] || "100")

        volume_muted = connect_params["_volume_muted"] == "true"

        {:ok,
         assign(socket,
           player_controls_id: "player-controls-#{Ecto.UUID.generate()}",
           start_time_tracker_id: "player-controls-start-time-tracker",
           end_time_tracker_id: "player-controls-end-time-tracker",
           time_slider_id: "player-controls-time-slider",
           volume_control_id: "volume-control-#{room_id}",
           fullscreen_control_id: "fullscreen-control-#{room_id}",
           layout: false,
           player: nil,
           room: room,
           user_id: user_id,
           display_name: display_name,
           volume_level: volume_level,
           volume_muted: volume_muted
         )}

      false ->
        {:ok,
         assign(socket,
           player: nil,
           start_time_tracker_id: nil,
           end_time_tracker_id: nil,
           time_slider_id: nil,
           user_id: user_id,
           display_name: display_name
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
    %{room: room, user_id: user_id, display_name: display_name} = socket.assigns
    Sessions.previous_track(room.id, user_id, display_name)
    {:noreply, socket}
  end

  def handle_event("next", _params, socket) do
    %{room: room, user_id: user_id, display_name: display_name} = socket.assigns
    Sessions.next_track(room.id, user_id, display_name)
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

  def handle_info({:track_ended, _room_id}, socket), do: {:noreply, socket}

  # ----------------------------------------------------------------------------
  # Chat event handling
  #

  def handle_info(
        {:display_name_changed, _room_id, user_id, new_name},
        %{assigns: %{user_id: user_id}} = socket
      ) do
    {:noreply, assign(socket, :display_name, new_name)}
  end

  def handle_info(
        {:display_name_changed, _room_id, _user_id, _new_name},
        socket
      ) do
    {:noreply, socket}
  end

  def handle_info({:message_sent, _room_id, _message}, socket),
    do: {:noreply, socket}

  def handle_info({:messages_updated, _room_id, _messages}, socket),
    do: {:noreply, socket}

  @spec assign_player(Phoenix.LiveView.Socket.t(), Sessions.Player.t()) ::
          Phoenix.LiveView.Socket.t()
  defp assign_player(socket, player), do: assign(socket, :player, player)

  defp on_play_click_event, do: @on_play_click
  defp on_pause_click_event, do: @on_pause_click

  defp render_default_seek_bar_value, do: "0:00"

  defp media_loaded?(""), do: false
  defp media_loaded?(_media_id), do: true
end
