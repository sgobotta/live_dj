defmodule LiveDjWeb.Components.QueueControls do
  @moduledoc """
  Responsible for displaying the queue controls
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Organizer
  alias LiveDj.Organizer.Queue

  @impl true
  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(assigns)
    }
  end

  @impl true
  def handle_event("save_queue", _params, %{assigns: assigns} = socket) do
    %{
      room: room,
      slug: slug,
      video_queue: video_queue,
      video_queue_controls: video_queue_controls
    } = assigns
    video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    {:ok, _room} = Organizer.update_room(room, %{queue: video_queue})

    Phoenix.PubSub.broadcast(
      LiveDj.PubSub,
      "room:" <> slug,
      {:save_queue,
        %{video_queue_controls: Queue.mark_as_saved(video_queue_controls)}}
    )

    {:noreply, socket}
  end
end
