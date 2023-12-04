defmodule LivedjWeb.ListComponent do
  @moduledoc false
  use LivedjWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-transparent py-1 rounded-lg pr-1">
      <div class="space-y-5 mx-auto max-w-7xl space-y-4 select-none">
        <div id={"#{@id}-items"} phx-hook="Sortable" data-list_id={@id}>
          <div
            :for={item <- @list}
            id={"#{item.external_id}-item"}
            data-id={item.external_id}
            class={"
              first:mt-0 last:mb-0
              #{get_background_color_by_track(item.external_id, @current_media)}
              #{if @state == :locked, do: "border-dashed", else: ""}
              my-2 rounded-xl border-gray-300 border-[1px]
              hover:cursor-grab
              drag-item:focus-within:ring-2 drag-item:focus-within:ring-offset-0
              drag-ghost:bg-zinc-200 drag-ghost:border-0 drag-ghost:ring-0 drag-ghost:cursor-grabbing
            "}
          >
            <div class="
              flex items-center h-14 px-1 h-14
              drag-ghost:opacity-0 gap-y-2
            ">
              <img
                class="inline-block h-12 w-12 rounded-lg ring-2 ring-white"
                src={item.thumbnail_url}
                alt={item.title}
              />
              <div class="
                flex-auto block
                text-sm leading-6 text-zinc-900
                p-1 px-1 h-8
                text-ellipsis overflow-hidden
              ">
                <%= item.title %>
              </div>
              <button
                type="button"
                class="w-10 -mt-1 flex-none"
                phx-click="remove_track"
                phx-value-track_id={item.external_id}
                data-confirm={gettext("Remove '%{title}'?", title: item.title)}
              >
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

  defp get_background_color_by_track(current_media_id, current_media_id),
    do: "bg-sky-200"

  defp get_background_color_by_track(_media_id, _current_media),
    do: "bg-gray-200"
end
