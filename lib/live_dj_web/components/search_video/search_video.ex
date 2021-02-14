defmodule LiveDjWeb.Components.SearchVideo do
  @moduledoc """
  Responsible for displaying and handling video search results
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Organizer.{Queue, Video}

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end

  @impl true
  def handle_event(
    "search",
    %{"search_field" => %{"query" => query}},
    %{assigns: %{video_queue: video_queue}} = socket
  ) do
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    opts = [maxResults: 25]
    {:ok, search_result, _pag_opts} = Tubex.Video.search_by_query(query, opts)
    search_result = Enum.map(search_result, fn search ->
      video = Video.from_tubex_video(search)
      is_queued = Queue.is_queued(video, video_queue)
      Video.update(video, %{is_queued: is_queued}) end)
    {:noreply,
      socket
      |> assign(:search_result, search_result)
      |> push_event("receive_search_completed_signal", %{})}
  end


  @impl true
  def handle_event("add_to_queue", selected_video, socket) do
    %{assigns: %{search_result: search_result, video_queue: video_queue,
      user: user}} = socket

    selected_video = Enum.find(
      search_result,
      fn search -> search.video_id == selected_video["video_id"] end
    ) |> Video.assign_user(user)
    video_queue = video_queue
      |> Enum.map(fn {v, _} -> v end)
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
