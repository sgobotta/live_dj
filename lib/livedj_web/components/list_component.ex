defmodule LivedjWeb.ListComponent do
  @moduledoc false
  use LivedjWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-transparent py-1 rounded-lg">
      <div class="space-y-5 mx-auto max-w-7xl px-1 space-y-4 select-none">
        <div id={"#{@id}-items"} phx-hook="Sortable" data-list_id={@id}>
          <div
            :for={item <- @list}
            id={"#{item.youtube_id}-item"}
            data-id={item.youtube_id}
            class={"
              #{if @state == :locked, do: "bg-gray-50 border-dashed", else: "bg-white"}
              bg-white my-2 rounded-xl border-gray-300 border-[1px]
              hover:cursor-grab
              drag-item:focus-within:ring-2 drag-item:focus-within:ring-offset-0
              drag-ghost:bg-zinc-200 drag-ghost:border-0 drag-ghost:ring-0 drag-ghost:cursor-grabbing
            "}
          >
            <div class="flex drag-ghost:opacity-0 gap-y-2 h-14 items-center px-1">
              <img
                class="inline-block h-12 w-12 rounded-lg ring-2 ring-white"
                src={item.thumbnail_url}
                alt={item.name}
              />
              <div class="flex-auto block text-sm leading-6 text-zinc-900 p-1 px-1">
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

  def handle_event("reposition_end", params, socket) do
    socket.assigns.on_drag_end.(socket, self(), params)
  end
end
