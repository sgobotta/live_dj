defmodule LivedjWeb.ListComponent do
  @moduledoc false
  use LivedjWeb, :live_component

  @on_play_click "on_play_click"

  def render(assigns) do
    ~H"""
    <div class="bg-transparent px-1 py-1 rounded-lg">
      <div class="space-y-5 mx-auto max-w-7xl select-none">
        <div
          id={"#{@id}-items"}
          phx-hook="Sortable"
          data-list_id={@id}
          data-current-media-id={@current_media || ""}
        >
          <div
            :for={{item, index} <- Enum.with_index(@list)}
            id={"#{item.external_id}-item"}
            data-id={item.external_id}
            data-nav-item={
              if current_media?(@current_media, item.external_id), do: true
            }
            role="option"
            aria-selected={current_media?(@current_media, item.external_id)}
            tabindex={if current_media?(@current_media, item.external_id), do: "-1"}
            class={"
              first:mt-0 last:mb-0
              #{if current_media?(@current_media, item.external_id),
                do: "text-green-500 dark:text-green-500 bg-zinc-300 dark:bg-zinc-700",
                else: "text-zinc-900 dark:text-zinc-100 bg-zinc-100 hover:bg-zinc-300 dark:bg-zinc-900 dark:hover:bg-zinc-700"
              }
              #{if @state == :locked, do: "border-dashed", else: ""}
              my-1 rounded-lg border-zinc-300 dark:border-zinc-700 border-[0px]
              hover:cursor-grab
              focus:outline-none focus-visible:outline-solid focus-visible:outline-1 focus-visible:outline-brand/60 focus-visible:outline-offset-1
              has-[:focus-visible]:outline-solid has-[:focus-visible]:outline-1 has-[:focus-visible]:outline-brand/60 has-[:focus-visible]:outline-offset-1
              drag-item:focus-within:ring-2 drag-item:focus-within:ring-offset-0
              drag-ghost:bg-zinc-200 drag-ghost:dark:bg-zinc-800 drag-ghost:border-0 drag-ghost:ring-0 drag-ghost:cursor-grabbing
            "}
          >
            <div class="
              relative flex items-center h-10 px-1
              drag-ghost:opacity-0 gap-y-2 gap-x-2
              group
            ">
              <%= if current_media?(@current_media, item.external_id) do %>
                <.link class="relative hover:cursor-grab" href="#" tabindex="-1">
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
                  class="relative inline-flex items-center justify-center rounded-full group focus:outline-none focus-ignite"
                  href="#"
                  tabindex="-1"
                  data-nav-item
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
                    do: "bg-green-500 text-zinc-100",
                    else: "bg-zinc-900 dark:bg-zinc-100"}
                "}>
                  {index + 1}
                </p>
              </div>
              <div class="
                flex-auto block
                text-xs leading-6 font-semibold
                p-1 px-1 h-8 w-5/6
                text-ellipsis overflow-hidden
              ">
                {item.title}
              </div>
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
