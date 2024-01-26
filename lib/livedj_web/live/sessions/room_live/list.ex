defmodule LivedjWeb.Sessions.RoomLive.List do
  use LivedjWeb, :live_view

  alias Livedj.Sessions
  alias Livedj.Sessions.Exceptions.SessionRoomError
  alias Livedj.Sessions.Room

  @on_play_click "on_play_click"

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    case connected?(socket) do
      true ->
        %Room{id: ^room_id} = room = Sessions.get_room!(room_id)

        {:ok, :joined} = Sessions.join_playlist(room_id)
        {:ok, :joined} = Sessions.join_player(room_id)

        {:ok,
         assign(socket,
           drag_state: :unlocked,
           search_form: to_form(%{}),
           search_result: [],
           layout: false,
           room: room,
           media_list: [],
           current_media: nil
         ), layout: {LivedjWeb.Layouts, :flash}}

      false ->
        {:ok, socket, layout: false}
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
  def handle_event("validate", %{"_target" => ["url"], "url" => url}, socket) do
    # Put your logic here to deal with the changes to the list order
    # and persist the data

    {:noreply, assign(socket, form: to_form(%{"url" => url}))}
  end

  def handle_event(@on_play_click, %{"media_id" => media_id}, socket) do
    case Sessions.play_track(socket.assigns.room.id, media_id) do
      :ok ->
        {:noreply, socket}

      :error ->
        {:noreply,
         socket
         |> put_flash(
           :warn,
           dgettext("errors", "The selected track could not be played")
         )}
    end
  end

  def handle_event("remove_track", %{"track_id" => track_id}, socket) do
    :ok = Sessions.remove_media(socket.assigns.room.id, track_id)

    {:noreply, socket}
  end

  # ----------------------------------------------------------------------------
  # Playlist event handling
  #

  @impl true
  def handle_info(
        {:playlist_joined, room_id, payload},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    drag_state =
      case payload.drag_state do
        :free ->
          :unlocked

        _other ->
          :locked
      end

    {:noreply,
     socket
     |> assign(:drag_state, drag_state)
     |> assign(:media_list, payload.media_list)}
  end

  @impl true
  def handle_info(
        {:track_added, room_id, media},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply,
     socket
     |> assign(media_list: socket.assigns.media_list ++ [media])}
  end

  @impl true
  def handle_info(
        {:track_removed, room_id, media_identifier},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    alias Livedj.Media.Video

    media_list =
      Enum.filter(socket.assigns.media_list, fn %Video{external_id: external_id} ->
        external_id != media_identifier
      end)

    {:noreply, assign(socket, media_list: media_list)}
  end

  @impl true
  def handle_info(
        {:track_moved, room_id, %{media_list: media_list}},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply,
     socket
     |> assign(media_list: media_list)}
  end

  @impl true
  def handle_info(:dragging_locked, socket) do
    {:noreply,
     socket
     |> assign(:drag_state, :locked)
     |> push_event("disable-drag", %{})}
  end

  @impl true
  def handle_info(:dragging_unlocked, socket) do
    {:noreply,
     socket
     |> assign(:drag_state, :unlocked)
     |> push_event("enable-drag", %{})}
  end

  @impl true
  def handle_info(
        {:dragging_cancelled, room_id},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply,
     socket
     |> assign(:drag_state, :unlocked)
     |> push_event("cancel-drag", %{})}
  end

  @impl true
  def handle_info({:dragging_cancelled, _room_id}, socket),
    do: {:noreply, socket}

  # ----------------------------------------------------------------------------
  # Player event handling
  #

  @impl true
  def handle_info(
        {:player_joined, _room_id, %{player: %Sessions.Player{} = player}},
        socket
      ) do
    {:noreply, assign_current_media(socket, player.media_id)}
  end

  @impl true
  def handle_info(
        {:player_state_changed, room_id, %Sessions.Player{}},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:player_play, _room_id, _player}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:player_pause, _room_id, _player}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:player_load_media, _room_id, %Sessions.Player{media_id: media_id}},
        socket
      ) do
    {:noreply, assign_current_media(socket, media_id)}
  end

  @spec assign_current_media(Phoenix.LiveView.Socket.t(), binary() | nil) ::
          Phoenix.LiveView.Socket.t()
  defp assign_current_media(socket, ""),
    do: assign(socket, :current_media, nil)

  defp assign_current_media(socket, media_id),
    do: assign(socket, :current_media, media_id)

  defp on_drag_start(room_id) do
    fn socket, _from ->
      case Sessions.lock_playlist_drag(room_id) do
        {:ok, :locked} ->
          {:noreply, socket}

        {:error, error} when error in [:already_locked, :not_an_owner] ->
          {:noreply, socket}
      end
    end
  end

  defp on_drag_end(room_id) do
    fn
      socket, from, params ->
        case params do
          %{
            "status" => "update",
            "id" => media_identifier,
            "insertedAfter" => inserted_after?,
            "relatedId" => target_media_id,
            "new" => new_index,
            "old" => old_index
          } ->
            Sessions.move_media(
              room_id,
              media_identifier,
              inserted_after?,
              String.replace(target_media_id, "-item", ""),
              new_index: new_index,
              old_index: old_index
            )

            {:noreply, socket}

          %{"status" => "noop"} ->
            :ok = Sessions.unlock_playlist_drag(room_id, from)
            {:noreply, socket}
        end
    end
  end
end
