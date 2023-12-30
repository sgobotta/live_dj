defmodule LivedjWeb.ListComponent do
  @moduledoc false
  use LivedjWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-transparent py-1 rounded-lg pr-1">
      <div class="space-y-5 mx-auto max-w-7xl space-y-4 select-none">
        <div id={"#{@id}-items"} phx-hook="Sortable" data-list_id={@id}>
          <div
            :for={{item, index} <- Enum.with_index(@list)}
            id={"#{item.external_id}-item"}
            data-id={item.external_id}
            class={"
              first:mt-0 last:mb-0
              #{classes_by_media(
                item.external_id,
                @current_media,
                "text-zinc-900 dark:text-zinc-100 bg-zinc-100 hover:bg-zinc-200 dark:bg-zinc-900 dark:hover:bg-zinc-800",
                "text-green-500 dark:text-green-500 bg-zinc-100 hover:bg-zinc-200 dark:bg-zinc-900 dark:hover:bg-zinc-800"
              )}
              #{if @state == :locked, do: "border-dashed", else: ""}
              my-2 rounded-xl border-zinc-300 dark:border-zinc-700 border-[0px]
              hover:cursor-grab
              drag-item:focus-within:ring-2 drag-item:focus-within:ring-offset-0
              drag-ghost:bg-zinc-200 drag-ghost:dark:bg-zinc-800 drag-ghost:border-0 drag-ghost:ring-0 drag-ghost:cursor-grabbing
            "}
          >
            <div class="
              flex items-center h-10 px-1 h-10
              drag-ghost:opacity-0 gap-y-2 gap-x-2
            ">
              <div class="absolute h-4 w-4">
                <div class="absolute top-3 -left-1 h-4 w-4 rounded-full">
                  <p class={"
                    rounded-full
                    text-center text-xs
                    text-zinc-100 dark:text-zinc-900
                    #{classes_by_media(
                      item.external_id,
                      @current_media,
                      "bg-zinc-900 dark:bg-zinc-100",
                      "bg-green-500 text-zinc-100"
                    )}
                  "}>
                    <%= index + 1 %>
                  </p>
                </div>
              </div>
              <img
                class="inline-block h-8 w-8 rounded-lg ring-[1px] ring-zinc-300 dark:ring-zinc-700"
                src={item.thumbnail_url}
                alt={item.title}
              />
              <div class="
                flex-auto block
                text-xs leading-6 font-semibold
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
                <.icon name="hero-x-mark" class="text-zinc-900 dark:text-zinc-100" />
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

  defp classes_by_media(
         current_media_id,
         current_media_id,
         _default_classes,
         current_media_classes
       ),
       do: current_media_classes

  defp classes_by_media(
         _media_id,
         _current_media,
         default_classes,
         _current_media_classes
       ),
       do: default_classes
end
