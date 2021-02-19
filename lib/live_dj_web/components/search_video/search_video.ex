defmodule LiveDjWeb.Components.SearchVideo do
  @moduledoc """
  Responsible for displaying and handling video search results
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Organizer.{Queue, Video}

  @impl true
  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(:search_query, "")
      |> assign(assigns)
    }
  end

  @impl true
  def handle_event("submit", _params,
    %{assigns: %{video_queue: video_queue, search_query: query}} = socket
  ) do
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    opts = [maxResults: 5]
    {:ok, search_result, _pag_opts} = Tubex.Video.search_by_query(query, opts)
    search_result = Enum.map(search_result, fn search ->
      video = Video.from_tubex_video(search)
      is_queued = Queue.is_queued(video, video_queue)
      Video.update(video, %{is_queued: is_queued}) end)
    {:noreply,
      socket
      |> assign(:search_result, Enum.with_index(search_result))
      |> push_event("receive_search_completed_signal", %{})}
  end

  @impl true
  def handle_event("search", %{"search_field" => search_field}, socket) do
    {:noreply, assign(socket, :search_query, search_field["query"])}
  end

  @impl true
  def handle_event("add_to_queue", selected_video, socket) do
    %{assigns: %{search_result: search_result, video_queue: video_queue,
      user: user}} = socket
    {selected_video, _index} = Enum.find(
      search_result,
      fn {_search, index} ->
        {selected_video, _} = Integer.parse(selected_video["video_id"])
        index == selected_video
      end
    )
    selected_video = Video.assign_user(selected_video, user)
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
      |> Queue.add_to_queue(selected_video)

    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:add_to_queue, %{
        updated_video_queue: video_queue,
        added_video_position: length(video_queue)}}
    )

    {:noreply, socket}
  end
end
