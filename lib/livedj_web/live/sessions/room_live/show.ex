defmodule LivedjWeb.Sessions.RoomLive.Show do
  @moduledoc false
  alias Livedj.Sessions.Room
  use LivedjWeb, {:live_view, layout: {LivedjWeb.Layouts, :session}}

  alias Livedj.Presence
  alias Livedj.Sessions
  alias Livedj.Sessions.Exceptions.SessionRoomError

  import Phoenix.Component

  @impl true
  def mount(params, _session, socket) do
    %Room{id: room_id} = room = Sessions.get_room!(params["id"])

    socket =
      assign(socket,
        list_lv_id: playlist_liveview_id(),
        player_container_id: "player-container",
        spinner_id: "player-spinner",
        backdrop_id: "player-backdrop",
        start_time_tracker_id: "player-controls-start-time-tracker",
        end_time_tracker_id: "player-controls-end-time-tracker",
        time_slider_id: "player-controls-time-slider",
        form: to_form(%{}),
        player: nil,
        room: room,
        room_url: nil,
        content_ready: connected?(socket)
      )

    socket =
      if connected?(socket) do
        {:ok, :joined} = Sessions.join_player(room_id)
        {:ok, _ref} = Presence.track_user(room_id, socket.assigns.current_user)

        push_event(socket, "on_container_mounted", %{
          backdrop_id: socket.assigns.backdrop_id,
          player_container_id: socket.assigns.player_container_id,
          spinner_id: socket.assigns.spinner_id,
          start_time_tracker_id: socket.assigns.start_time_tracker_id,
          end_time_tracker_id: socket.assigns.end_time_tracker_id,
          time_slider_id: socket.assigns.time_slider_id
        })
      else
        socket
      end

    {:ok, socket}
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
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "#{socket.assigns.room.name}")
    |> assign(:room_url, nil)
  end

  defp apply_action(socket, :welcome, _params) do
    room_url = url(~p"/sessions/rooms/#{socket.assigns.room}")

    socket
    |> assign(:page_title, "#{socket.assigns.room.name}")
    |> assign(:room_url, room_url)
  end

  defp apply_action(socket, :browse, _params) do
    socket
    |> assign(:page_title, "#{socket.assigns.room.name}")
  end

  defp apply_action(socket, :help, _params) do
    socket
    |> assign(:page_title, "#{socket.assigns.room.name}")
  end

  # ----------------------------------------------------------------------------
  # Client side event handling
  #

  def handle_event("open_share_modal", _params, socket) do
    {:noreply,
     push_patch(socket, to: ~p"/sessions/rooms/#{socket.assigns.room}/welcome")}
  end

  def handle_event("open_help_modal", _params, socket) do
    {:noreply,
     push_patch(socket, to: ~p"/sessions/rooms/#{socket.assigns.room}/help")}
  end

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
    :ok = Sessions.report_track_ended(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("on_player_loaded", _params, socket) do
    socket =
      if connected?(socket) and is_nil(socket.assigns.player) do
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

  @out_of_sync_threshold_seconds 5

  def handle_event(
        "seek_committed",
        %{"committed_time" => committed_time},
        socket
      ) do
    room_id = socket.assigns.room.id

    case Sessions.get_player(room_id) do
      {:ok, %Sessions.Player{state: state, current_time: room_time}}
      when state in [:playing, :paused] ->
        delta = abs(trunc(room_time) - trunc(committed_time))

        if delta > @out_of_sync_threshold_seconds do
          message =
            if committed_time > room_time do
              gettext("You're %{delta}s ahead of the room.", delta: delta)
            else
              gettext("You're %{delta}s behind the room.", delta: delta)
            end

          {:noreply,
           push_event(socket, "player_out_of_sync", %{message: message})}
        else
          {:noreply, socket}
        end

      _other ->
        {:noreply, socket}
    end
  end

  def handle_event("on_player_resync", _params, socket) do
    case Sessions.get_player(socket.assigns.room.id) do
      {:ok, %Sessions.Player{current_time: room_time}} ->
        {:noreply,
         push_event(socket, "set_current_time", %{current_time: room_time})}

      _error ->
        {:noreply, socket}
    end
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

  def handle_info({:track_added, _room_id, media}, socket) do
    send_update(LivedjWeb.Components.SearchBarComponent,
      id: "browse-search-bar",
      track_added: media
    )

    {:noreply, socket}
  end

  def handle_info({:track_removed, _room_id, external_id}, socket) do
    send_update(LivedjWeb.Components.SearchBarComponent,
      id: "browse-search-bar",
      track_removed: external_id
    )

    {:noreply, socket}
  end

  def handle_info({:track_moved, _room_id, _payload}, socket),
    do: {:noreply, socket}

  def handle_info(:dragging_locked, socket), do: {:noreply, socket}

  def handle_info(:dragging_unlocked, socket), do: {:noreply, socket}

  def handle_info({:dragging_cancelled, _room_id}, socket),
    do: {:noreply, socket}

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
        {:player_play, _room_id, %Sessions.Player{}},
        socket
      ) do
    # Broadcasted request to send a play signal to the player
    {:noreply,
     push_event(socket, "play_video", %{
       callback_event: "on_player_playing"
     })}
  end

  def handle_info({:player_pause, _room_id, %Sessions.Player{}}, socket) do
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

  def handle_info({:track_ended, _room_id}, socket), do: {:noreply, socket}

  @spec assign_player(Phoenix.LiveView.Socket.t(), Sessions.Player.t()) ::
          Phoenix.LiveView.Socket.t()
  defp assign_player(socket, player), do: assign(socket, :player, player)

  defp playlist_liveview_id, do: "playlist-lv-#{Ecto.UUID.generate()}"
end
