defmodule LivedjWeb.Sessions.RoomLive.Show do
  @moduledoc false
  alias Livedj.Sessions.Room
  use LivedjWeb, {:live_view, layout: {LivedjWeb.Layouts, :session}}

  alias Livedj.Sessions
  alias Livedj.Sessions.Exceptions.SessionRoomError

  import Phoenix.Component

  @impl true
  def mount(params, _session, socket) do
    case connected?(socket) do
      true ->
        %Room{id: room_id} = room = Sessions.get_room!(params["id"])
        {:ok, :joined} = Sessions.join_player(room_id)

        {:ok,
         assign(socket,
           list_lv_id: playlist_liveview_id(),
           player_container_id: player_container_id(),
           spinner_id: spinner_id(),
           backdrop_id: backdrop_id(),
           start_time_tracker_id: "player-controls-start-time-tracker",
           end_time_tracker_id: "player-controls-end-time-tracker",
           time_slider_id: "player-controls-time-slider",
           form: to_form(%{}),
           player: nil,
           room: room
         )}

      false ->
        {:ok, socket}
    end
  rescue
    error in SessionRoomError ->
      case error do
        %SessionRoomError{reason: :room_not_found} ->
          {:ok,
           socket
           |> put_flash(:error, dgettext("errors", "The room doesn't exist"))
           |> redirect(to: ~p"/")}
      end

    _error ->
      {:ok,
       socket
       |> put_flash(:error, dgettext("errors", "Something went wrong!"))
       |> redirect(to: ~p"/")}
  end

  @impl true
  def handle_params(%{"id" => _id} = params, _url, socket) do
    case connected?(socket) do
      true ->
        {:noreply,
         socket
         |> apply_action(socket.assigns.live_action, params)}

      false ->
        {:noreply, socket}
    end
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "(#{socket.assigns.room.name})")
  end

  # ----------------------------------------------------------------------------
  # Client side event handling
  #

  def handle_event("on_player_play", _params, socket) do
    # On click event callback
    :ok = Sessions.play(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("on_player_pause", %{"current_time" => current_time}, socket) do
    # On click event callback
    :ok = Sessions.pause(socket.assigns.room.id, at: current_time)
    {:noreply, socket}
  end

  def handle_event("on_player_playing", _params, socket) do
    # The player state changed to playing.
    {:noreply, socket}
  end

  def handle_event("on_player_paused", _params, socket) do
    # The player state changed to paused.
    {:noreply, socket}
  end

  def handle_event("on_player_ended", _params, socket) do
    # The player state changed to ended.
    {:noreply, socket}
  end

  def handle_event("on_player_container_mount", _params, socket) do
    socket =
      if connected?(socket),
        do:
          push_event(socket, "on_container_mounted", %{
            backdrop_id: socket.assigns.backdrop_id,
            player_container_id: socket.assigns.player_container_id,
            spinner_id: socket.assigns.spinner_id,
            start_time_tracker_id: socket.assigns.start_time_tracker_id,
            end_time_tracker_id: socket.assigns.end_time_tracker_id,
            time_slider_id: socket.assigns.time_slider_id
          }),
        else: socket

    {:noreply, socket}
  end

  def handle_event("on_player_loaded", _params, socket) do
    socket =
      if connected?(socket) do
        {:ok, %Sessions.Player{} = player} =
          Sessions.get_player(socket.assigns.room.id)

        socket
        |> assign_player(player)
        |> push_event("show_player", %{callback_event: "on_player_visible"})
        |> push_event("load_video", player)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("on_player_visible", _params, socket) do
    {:noreply, socket}
  end

  # ----------------------------------------------------------------------------
  # Server side Playlist event handling
  #

  @impl true
  def handle_info(
        {:playlist_joined, room_id, _payload},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply, socket}
  end

  # ----------------------------------------------------------------------------
  # Server side Player event handling
  #

  def handle_info(
        {:player_joined, _room_id, %{player: %Sessions.Player{}}},
        socket
      ) do
    {:noreply, socket}
  end

  def handle_info(
        {:player_state_changed, room_id, %Sessions.Player{}},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_info(
        {:player_play, %Sessions.Player{}},
        socket
      ) do
    # Broadcasted request to send a play signal to the player
    {:noreply,
     push_event(socket, "play_video", %{
       callback_event: "on_player_playing"
     })}
  end

  def handle_info({:player_pause, %Sessions.Player{}}, socket) do
    # Broadcasted request to send a pause signal to the player
    {:noreply,
     push_event(socket, "pause_video", %{callback_event: "on_player_paused"})}
  end

  def handle_info(
        {:player_load_media, _room_id, %Sessions.Player{} = player},
        socket
      ) do
    {:noreply,
     socket
     |> assign_player(player)
     |> push_event("load_video", player)}
  end

  @spec assign_player(Phoenix.LiveView.Socket.t(), Sessions.Player.t()) ::
          Phoenix.LiveView.Socket.t()
  defp assign_player(socket, player), do: assign(socket, :player, player)

  defp playlist_liveview_id, do: "playlist-lv-#{Ecto.UUID.generate()}"
  defp player_container_id, do: "player-container-#{Ecto.UUID.generate()}"
  defp spinner_id, do: "spinner-#{Ecto.UUID.generate()}"
  defp backdrop_id, do: "backdrop-#{Ecto.UUID.generate()}"
end
