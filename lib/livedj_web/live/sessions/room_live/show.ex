defmodule LivedjWeb.Sessions.RoomLive.Show do
  @moduledoc false
  alias Livedj.Sessions.Room
  use LivedjWeb, :live_view

  alias Livedj.Sessions
  # alias Livedj.Sessions.Room

  @impl true
  def mount(params, _session, socket) do
    with true <- connected?(socket),
         %Room{id: room_id} = room <- Sessions.get_room!(params["id"]),
         {:ok, :joined} <- Sessions.join_playlist(room_id) do
      {:ok,
       assign(socket,
         drag_state: :unlocked,
         form: to_form(%{}),
         room: room,
         media_list: []
       )}
    else
      _err ->
        {:ok, socket}
    end
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
  def handle_event("validate", %{"_target" => ["url"], "url" => url}, socket) do
    # Put your logic here to deal with the changes to the list order
    # and persist the data

    {:noreply, assign(socket, form: to_form(%{"url" => url}))}
  end

  def handle_event("save", %{"url" => url}, socket) do
    with {:ok, media_id} <- validate_url(url),
         {:ok, media} <- Sessions.fetch_media_metadata_by_id(media_id),
         {:ok, media} <- Sessions.create_media(media),
         {:ok, :added} <- Sessions.add_media(socket.assigns.room.id, media) do
      {:noreply,
       socket
       |> assign(form: to_form(%{}))
       |> assign(media_list: socket.assigns.media_list ++ [media])}
    else
      _else ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           dgettext("errors", "The youtube url is not valid")
         )}
    end
  end

  def handle_event("previous", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("next", _params, socket) do
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

    {:noreply, assign(socket, :drag_state, drag_state)}
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
    fn socket, from ->
      :ok = Sessions.unlock_playlist_drag(room_id, from)

      {:noreply, socket}
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
