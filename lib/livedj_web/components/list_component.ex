defmodule LivedjWeb.ListComponent do
  @moduledoc false
  use LivedjWeb, :live_component

  @on_play_click "on_play_click"

  def render(assigns) do
    ~H"""
    <div class="bg-transparent py-1 rounded-lg pr-1">
      <div class="space-y-5 mx-auto max-w-7xl space-y-4 select-none pl-1">
        <div id={"#{@id}-items"} phx-hook="Sortable" data-list_id={@id}>
          <div
            :for={{item, index} <- Enum.with_index(@list)}
            id={"#{item.external_id}-item"}
            data-id={item.external_id}
            class={"
              first:mt-0 last:mb-0
              #{if current_media?(@current_media, item.external_id),
                do: "text-green-500 dark:text-green-500 bg-zinc-300 dark:bg-zinc-600 hover:bg-zinc-200 dark:bg-zinc-900 dark:hover:bg-zinc-500",
                else: "text-zinc-900 dark:text-zinc-100 bg-zinc-100 hover:bg-zinc-200 dark:bg-zinc-900 dark:hover:bg-zinc-800"
              }
              #{if @state == :locked, do: "border-dashed", else: ""}
              my-2 rounded-xl border-zinc-300 dark:border-zinc-700 border-[0px]
              hover:cursor-grab
              drag-item:focus-within:ring-2 drag-item:focus-within:ring-offset-0
              drag-ghost:bg-zinc-200 drag-ghost:dark:bg-zinc-800 drag-ghost:border-0 drag-ghost:ring-0 drag-ghost:cursor-grabbing
            "}
          >
            <div class="
              relative flex items-center h-10 px-1 h-10
              drag-ghost:opacity-0 gap-y-2 gap-x-2
              group
            ">
              <%= if current_media?(@current_media, item.external_id) do %>
                <.link
                  class="relative focus:rounded-full hover:cursor-grab"
                  href="#"
                  tabindex="-1"
                >
                  <img
                    class="
                      inline-block h-8 w-8 rounded-lg
                      ring-[1px] ring-zinc-300 dark:ring-zinc-700
                    "
                    src={item.thumbnail_url}
                    alt={item.title}
                  />
                </.link>
              <% else %>
                <.link
                  class="relative focus:ring-2 focus:ring-zinc-900 focus:dark:ring-zinc-50 group focus:rounded-full"
                  href="#"
                  tabindex="0"
                  phx-click={on_play_click_event()}
                  phx-value-media_id={item.external_id}
                >
                  <img
                    class="
                      inline-block h-8 w-8 rounded-lg ring-[1px] ring-zinc-300 dark:ring-zinc-700
                      transition duration-100 opacity-100 group-hover:!opacity-0 group-focus:!opacity-0
                    "
                    src={item.thumbnail_url}
                    alt={item.title}
                  />
                  <div class="
                      absolute bottom-0 left-0
                      transition duration-300 opacity-0 group-hover:!opacity-100 group-focus:!opacity-100
                      w-8 h-8 rounded-lg
                      bg-transparent
                      cursor-pointer
                      text-zinc-900 dark:text-zinc-100
                      hover:text-green-500 dark:hover:text-green-500
                      hover:scale-110 focus:scale-110 active:scale-[0.95]
                      active:text-green-300 dark:active:text-green-700
                      focus:text-green-500 dark:focus:text-green-500
                      active:text-green-300 dark:active:text-green-700
                      group-focus:text-green-500 dark:group-focus:text-green-500
                    ">
                    <.icon name="hero-play-circle-solid" class="h-8 w-8" />
                  </div>
                </.link>
              <% end %>
              <div class="absolute top-6 -left-1 h-4 w-4 rounded-full">
                <p class={"
                  rounded-full h-4 w-4
                  flex justify-center items-center
                  text-center text-[0.5rem]
                  text-zinc-100 dark:text-zinc-900
                  #{if current_media?(@current_media, item.external_id),
                    do: "bg-zinc-900 dark:bg-zinc-100",
                    else: "bg-green-500 text-zinc-100"}
                "}>
                  <%= index + 1 %>
                </p>
              </div>
              <div class="
                flex-auto block
                text-xs leading-6 font-semibold
                p-1 px-1 h-8 w-5/6
                text-ellipsis overflow-hidden
              ">
                <%= item.title %>
              </div>
              <button
                type="button"
                class="
                  cursor-default
                  transition-all duration-300
                  w-6 h-6 rounded mr-1 flex-none hover:bg-gray-300 hover:dark:bg-gray-700
                  text-zinc-900 dark:text-zinc-100 hover:text-red-500 hover:dark:text-red-500
                  focus:ring-2 focus:ring-zinc-900 focus:dark:ring-zinc-50
                "
                phx-click="remove_track"
                phx-value-track_id={item.external_id}
                tabindex="0"
                href="#"
                data-confirm={gettext("Remove '%{title}'?", title: item.title)}
              >
                <.icon name="hero-x-mark" class="" />
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

  defp current_media?(media_id, media_id), do: true
  defp current_media?(_media_id, _another_media_id), do: false

  defp on_play_click_event, do: @on_play_click
end
