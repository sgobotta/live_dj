defmodule LivedjWeb.Admin.Sessions.RoomLive.Index do
  use LivedjWeb, :live_view

  import LivedjWeb.Gettext

  alias Livedj.Sessions
  alias Livedj.Sessions.Room

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :rooms, Sessions.list_rooms())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Room"))
    |> assign(:room, Sessions.get_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Room"))
    |> assign(:room, %Room{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Rooms"))
    |> assign(:room, nil)
  end

  @impl true
  def handle_info(
        {LivedjWeb.Admin.Sessions.RoomLive.FormComponent, {:saved, room}},
        socket
      ) do
    {:noreply, stream_insert(socket, :rooms, room)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room = Sessions.get_room!(id)
    {:ok, _} = Sessions.delete_room(room)

    {:noreply, stream_delete(socket, :rooms, room)}
  end
end
