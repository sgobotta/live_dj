defmodule LivedjWeb.Admin.Sessions.RoomLive.Show do
  use LivedjWeb, :live_view

  alias Livedj.Sessions

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, __params, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:room, Sessions.get_room!(id))}
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
end
