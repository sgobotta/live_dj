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
           is_playing: false,
           form: to_form(%{}),
           room: room
         )}

      false ->
        {:ok, assign(socket, is_playing: false)}
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

  @impl true
  def handle_event("previous", _params, socket) do
    Sessions.previous_track(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("next", _params, socket) do
    Sessions.next_track(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("play", _params, socket) do
    :ok = Sessions.play(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("pause", _params, socket) do
    :ok = Sessions.pause(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("on_player_play", _params, socket) do
    # A request to play a song has been sent to the player..
    {:noreply, assign(socket, is_playing: true)}
  end

  def handle_event("on_player_playing", _params, socket) do
    # The player state changed to playing.
    {:noreply, socket}
  end

  def handle_event("on_player_pause", _params, socket) do
    # A request to pause a song has been sent to the player.
    {:noreply, assign(socket, is_playing: false)}
  end

  def handle_event("on_player_paused", _params, socket) do
    # The player state changed to paused.
    {:noreply, socket}
  end

  def handle_event("on_player_ended", _params, socket) do
    # The player state changed to ended.
    {:noreply, assign(socket, is_playing: false)}
  end

  def handle_event("on_player_container_mount", _params, socket) do
    socket =
      if connected?(socket),
        do:
          push_event(socket, "on_container_mounted", %{
            backdrop_id: socket.assigns.backdrop_id,
            player_container_id: socket.assigns.player_container_id,
            spinner_id: socket.assigns.spinner_id
          }),
        else: socket

    {:noreply, socket}
  end

  def handle_event("player_loaded", _params, socket) do
    socket =
      if connected?(socket) do
        {:ok, %Sessions.Player{} = player} =
          Sessions.get_player(socket.assigns.room.id)

        socket
        |> push_event("show_player", %{})
        |> push_event("load_video", player)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("player_visible", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:playlist_joined, room_id, _payload},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_info(
        {:player_joined, _room_id, %{player: %Sessions.Player{}}},
        socket
      ) do
    {:noreply, socket}
  end

  def handle_info(:player_play, socket) do
    {:noreply, push_event(socket, "play_video", %{})}
  end

  def handle_info(:player_pause, socket) do
    {:noreply, push_event(socket, "pause_video", %{})}
  end

  def handle_info(
        {:player_load_media, _room_id, %Sessions.Player{} = player},
        socket
      ) do
    {:noreply, push_event(socket, "load_video", player)}
  end

  defp playlist_liveview_id, do: "playlist-lv-#{Ecto.UUID.generate()}"
  defp player_container_id, do: "player-container-#{Ecto.UUID.generate()}"
  defp spinner_id, do: "spinner-#{Ecto.UUID.generate()}"
  defp backdrop_id, do: "backdrop-#{Ecto.UUID.generate()}"
end
