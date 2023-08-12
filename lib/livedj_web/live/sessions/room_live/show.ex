defmodule LivedjWeb.Sessions.RoomLive.Show do
  @moduledoc false
  use LivedjWeb, :live_view

  alias Livedj.Sessions
  alias Livedj.Sessions.Room

  @impl true
  def mount(_params, _session, socket) do
    list = [
      %{name: "Bread", id: 1, position: 1, status: :in_progress},
      %{name: "Butter", id: 2, position: 2, status: :in_progress},
      %{name: "Milk", id: 3, position: 3, status: :in_progress},
      %{name: "Bananas", id: 4, position: 4, status: :in_progress},
      %{name: "Eggs", id: 5, position: 5, status: :in_progress}
    ]

    {:ok, assign(socket, shopping_list: list, form: to_form(%{}))}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    {:noreply,
     socket
     |> assign(:room, Sessions.get_room!(id))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "(#{socket.assigns.room.name})")
  end
end
