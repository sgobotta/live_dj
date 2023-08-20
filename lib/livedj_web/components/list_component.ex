defmodule LivedjWeb.ListComponent do
  @moduledoc false
  use LivedjWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 py-4 rounded-lg">
      <div class="space-y-5 mx-auto max-w-7xl px-4 space-y-4">
        <div id={"#{@id}-items"} phx-hook="Sortable" data-list_id={@id}>
          <div
            :for={item <- @list}
            id={"#{@id}-#{item.id}"}
            data-id={item.id}
            class={"
              #{if @state == :locked, do: "bg-gray-50 border-dashed", else: "bg-white"}
              draggable
            "}
          >
            <div class="flex drag-ghost:opacity-0 gap-y-2">
              <button type="button" class="w-10">
                <.icon
                  name="hero-check-circle"
                  class={"
                    w-7 h-7
                    #{if item.status == :completed, do: "bg-green-600", else: "bg-gray-300"}
                  "}
                />
              </button>
              <div class="flex-auto block text-sm leading-6 text-zinc-900">
                <%= item.name %>
              </div>
              <button type="button" class="w-10 -mt-1 flex-none">
                <.icon name="hero-x-mark" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  def handle_event("reposition_start", _params, socket) do
    socket.assigns.on_drag_start.(socket, self())
  end

  def handle_event("reposition_end", _params, socket) do
    socket.assigns.on_drag_end.(socket, self())
  end
end
