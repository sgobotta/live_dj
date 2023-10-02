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
        %Room{} = room = Sessions.get_room!(params["id"])
        # {:ok, :joined} = Sessions.join_playlist(room_id)

        {:ok,
         assign(socket,
           list_lv_id: Ecto.UUID.generate(),
           player_container_id: Ecto.UUID.generate(),
           spinner_container_id: Ecto.UUID.generate(),
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
    {:noreply, socket}
  end

  def handle_event("next", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("play", _params, socket) do
    {:noreply, push_event(socket, "play_video", %{})}
  end

  def handle_event("on_player_playing", _params, socket) do
    {:noreply, assign(socket, is_playing: true)}
  end

  def handle_event("pause", _params, socket) do
    {:noreply, push_event(socket, "pause_video", %{})}
  end

  def handle_event("on_player_paused", _params, socket) do
    {:noreply, assign(socket, is_playing: false)}
  end

  def handle_event("on_player_container_mount", _params, socket) do
    socket =
      if connected?(socket),
        do:
          push_event(socket, "on_container_mounted", %{
            container_id: "player-#{socket.assigns.player_container_id}"
          }),
        else: socket

    {:noreply, socket}
  end

  def handle_event("player_loaded", _params, socket) do
    socket =
      if connected?(socket),
        do:
          push_event(socket, "show_player", %{
            loader_container_id:
              "spinner-#{socket.assigns.spinner_container_id}"
          }),
        else: socket

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
end
