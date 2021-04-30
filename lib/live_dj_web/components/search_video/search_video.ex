defmodule LiveDjWeb.Components.SearchVideo do
  @moduledoc """
  Responsible for displaying and handling video search results
  """
  require Logger

  use LiveDjWeb, :live_component

  alias LiveDj.Collections
  alias LiveDj.Collections.Video
  alias LiveDj.Organizer.{Queue, QueueItem}

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:search_query, "")
     |> assign(assigns)}
  end

  @impl true
  def handle_event(
        "submit",
        _params,
        %{assigns: %{video_queue: video_queue, search_query: query}} = socket
      ) do
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    opts = [maxResults: 20]

    search_result =
      case Tubex.Video.search_by_query(query, opts) do
        {:ok, search_result, _pag_opts} ->
          search_result

        {:error, %{"error" => %{"errors" => errors}}} ->
          for error <- errors do
            Logger.error(error["message"])
          end

          []
      end

    search_result =
      Enum.map(search_result, fn search ->
        video = QueueItem.from_tubex_video(search)
        is_queued = Queue.is_queued(video, video_queue)
        QueueItem.update(video, %{is_queued: is_queued})
      end)
      |> Enum.with_index()

    send(self(), {:receive_search_results, search_result})

    {:noreply,
     socket
     |> push_event("receive_search_completed_signal", %{})}
  end

  @impl true
  def handle_event("search", %{"search_field" => search_field}, socket) do
    {:noreply, assign(socket, :search_query, search_field["query"])}
  end

  @impl true
  def handle_event("add_to_queue", selected_video, socket) do
    %{
      assigns: %{
        search_result: search_result,
        video_queue: video_queue,
        user: user,
        current_user: current_user,
        visitor: visitor
      }
    } = socket

    {selected_video, _index} =
      Enum.find(
        search_result,
        fn {_search, index} ->
          {selected_video, _} = Integer.parse(selected_video["video_id"])
          index == selected_video
        end
      )

    _video = Collections.create_video(Video.from_tubex(selected_video))

    user_id =
      if visitor do
        nil
      else
        current_user.id
      end

    selected_video = QueueItem.assign_user(selected_video, user, user_id)

    video_queue =
      Enum.map(video_queue, fn {v, _} -> v end)
      |> Queue.add_to_queue(selected_video)

    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> socket.assigns.slug,
      {:add_to_queue,
       %{
         updated_video_queue: video_queue,
         added_video_position: length(video_queue)
       }}
    )

    {:noreply, socket}
  end

  defp render_button("add", video_index, true, assigns) do
    id = "search-element-button-#{video_index + 1}"

    props = %{
      classes: "disabled",
      click_event: "",
      icon: "icons/search/add",
      icon_classes: "show-check-button",
      id: id,
      value: video_index
    }

    render_button(props, assigns)
  end

  defp render_button("add", video_index, false, assigns) do
    id = "search-element-button-#{video_index + 1}"

    props = %{
      classes: "search-control-enabled clickeable",
      click_event: "add_to_queue",
      icon: "icons/search/add",
      icon_classes: "show-add-button",
      id: id,
      value: video_index
    }

    render_button(props, assigns)
  end

  defp render_button(
         %{
           classes: classes,
           icon: icon,
           icon_classes: icon_classes,
           id: id,
           value: value,
           click_event: click_event
         },
         assigns
       ) do
    ~L"""
      <a
        class="<%= classes %>"
        id="<%= id %>"
        phx-click="<%= click_event %>"
        phx-target="<%= assigns %>"
        phx-value-video_id="<%= value %>"
      >
        <%= render_svg(icon, "h-8 w-8 #{icon_classes}") %>
      </a>
    """
  end

  defp render_svg(icon, classes) do
    PhoenixInlineSvg.Helpers.svg_image(LiveDjWeb.Endpoint, icon, class: classes)
  end
end
