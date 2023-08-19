defmodule LivedjWeb.Sessions.RoomLive.Show do
  @moduledoc false
  use LivedjWeb, :live_view

  alias Livedj.Sessions
  # alias Livedj.Sessions.Room

  @impl true
  def mount(params, _session, socket) do
    case connected?(socket) do
      true ->
        socket =
          socket
          |> assign(:room, Sessions.get_room!(params["id"]))
          |> assign(:current_track, Sessions.current_track(params["id"]))

        :ok = LivedjWeb.Endpoint.subscribe("room:#{socket.assigns.room.id}")

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
           shopping_list: list,
           form: to_form(%{})
         )}

      false ->
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
  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: _topic,
          event: "dragging_locked",
          payload: _payload
        },
        socket
      ) do
    {:noreply,
     socket
     |> assign(:drag_state, :locked)
     |> push_event("disable-drag", %{})}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: _topic,
          event: "dragging_unlocked",
          payload: _payload
        },
        socket
      ) do
    {:noreply,
     socket
     |> assign(:drag_state, :unlocked)
     |> push_event("enable-drag", %{})}
  end
end
