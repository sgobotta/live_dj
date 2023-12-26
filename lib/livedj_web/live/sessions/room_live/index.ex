defmodule LivedjWeb.Sessions.RoomLive.Index do
  @moduledoc false
  use LivedjWeb, :live_view

  alias Livedj.Sessions
  alias Livedj.Sessions.Room

  @impl true
  def mount(_params, _session, socket) do
    case connected?(socket) do
      true ->
        {:ok, stream(socket, :rooms, Sessions.list_rooms())}

      false ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(
        {LivedjWeb.Sessions.RoomLive.FormComponent, {:saved, room}},
        socket
      ) do
    {:noreply, stream_insert(socket, :rooms, room)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Rooms"))
    |> assign(:room, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Room"))
    |> assign(:room, %Room{})
  end
end
