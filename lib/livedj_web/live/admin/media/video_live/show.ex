defmodule LivedjWeb.Admin.Media.VideoLive.Show do
  use LivedjWeb, :live_view

  import LivedjWeb.Gettext

  alias Livedj.Media

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _params, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:video, Media.get_video!(id))}
  end

  defp page_title(:show), do: gettext("Show Video")
  defp page_title(:edit), do: gettext("Edit Video")
end
