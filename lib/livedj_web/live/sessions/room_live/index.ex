defmodule LivedjWeb.Sessions.RoomLive.Index do
  @moduledoc false
  use LivedjWeb, :live_view

  alias Livedj.Sessions

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

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Rooms"))
    |> assign(:room, nil)
  end
end
