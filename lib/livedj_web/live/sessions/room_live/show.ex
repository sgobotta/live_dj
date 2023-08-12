defmodule LivedjWeb.Sessions.RoomLive.Show do
  @moduledoc false
  use LivedjWeb, :live_view

  alias Livedj.Sessions
  alias Livedj.Sessions.Room

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
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
