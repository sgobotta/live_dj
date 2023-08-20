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
      # :ok = LivedjWeb.Endpoint.subscribe("room:#{room_id}")

      list = [
        %{name: "Bread", id: 1, position: 1, status: :in_progress},
        %{name: "Butter", id: 2, position: 2, status: :in_progress},
        %{name: "Milk", id: 3, position: 3, status: :in_progress},
        %{name: "Bananas", id: 4, position: 4, status: :in_progress},
        %{name: "Eggs", id: 5, position: 5, status: :in_progress}
      ]

      {:ok,
       assign(socket,
         drag_state: :unlocked,
         form: to_form(%{}),
         room: room,
         shopping_list: list
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
  def handle_event("validate", %{"_target" => ["name"], "name" => name}, socket) do
    # Put your logic here to deal with the changes to the list order
    # and persist the data

    {:noreply, assign(socket, form: to_form(%{"name" => name}))}
  end

  def handle_event("save", %{"name" => name}, socket) do
    # Put your logic here to deal with the changes to the list order
    # and persist the data

    new_item = %{
      name: name,
      id: Ecto.UUID.generate(),
      position: length(socket.assigns.shopping_list) + 1,
      status: :in_progress
    }

    {:noreply,
     socket
     |> assign(form: to_form(%{}))
     |> assign(shopping_list: socket.assigns.shopping_list ++ [new_item])}
  end

  def handle_event("previous", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("next", _params, socket) do
    {:noreply, socket}
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
end
