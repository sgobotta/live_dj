defmodule LivedjWeb.Sessions.RoomLive.List do
  use LivedjWeb, :live_view

  alias Livedj.Sessions
  alias Livedj.Sessions.Exceptions.SessionRoomError
  alias Livedj.Sessions.Room

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    case connected?(socket) do
      true ->
        %Room{id: ^room_id} = room = Sessions.get_room!(room_id)

        {:ok, :joined} = Sessions.join_playlist(room_id)

        {:ok,
         assign(socket,
           is_playing: false,
           drag_state: :unlocked,
           form: to_form(%{}),
           layout: false,
           room: room,
           media_list: []
         ), layout: {LivedjWeb.Layouts, :flash}}

      false ->
        {:ok, assign(socket, is_playing: false), layout: false}
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

  def handle_event("add", %{"url" => url}, socket) do
    with {:ok, media_id} <- validate_url(url),
         {:ok, :added} <- Sessions.add_media(socket.assigns.room.id, media_id) do
      {:noreply,
       socket
       |> assign(form: to_form(%{}))
       |> put_flash(:info, gettext("Track queued to playlist"))}
    else
      {:error, :invalid_url} ->
        {:noreply,
         socket
         |> assign(form: to_form(%{}))
         |> put_flash(
           :warn,
           dgettext("errors", "The youtube url is not valid")
         )}

      {:error, {type, msg}} when type in [:warn, :error] and is_binary(msg) ->
        {:noreply,
         socket
         |> assign(form: to_form(%{}))
         |> put_flash(type, msg)}
    end
  end

  def handle_event("remove_track", %{"track_id" => track_id}, socket) do
    :ok = Sessions.remove_media(socket.assigns.room.id, track_id)

    {:noreply, socket}
  end

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

  defp validate_url(url) do
    case URI.parse(url) do
      %URI{query: query} when not is_nil(query) ->
        {:ok, String.replace(query, "v=", "")}

      _uri ->
        {:error, :invalid_url}
    end
  end
end