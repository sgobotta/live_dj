defmodule LivedjWeb.Admin.Media.VideoLive.Index do
  use LivedjWeb, :live_view

  import LivedjWeb.Gettext

  alias Livedj.Media
  alias Livedj.Media.Video

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :videos, Media.list_videos())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("Edit Video"))
    |> assign(:video, Media.get_video!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Video"))
    |> assign(:video, %Video{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Videos"))
    |> assign(:video, nil)
  end

  @impl true
  def handle_info(
        {LivedjWeb.Admin.Media.VideoLive.FormComponent, {:saved, video}},
        socket
      ) do
    {:noreply, stream_insert(socket, :videos, video)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    video = Media.get_video!(id)
    {:ok, _} = Media.delete_video(video)

    {:noreply, stream_delete(socket, :videos, video)}
  end
end
