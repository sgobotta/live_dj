defmodule LivedjWeb.Components.AddVideoComponent do
  @moduledoc false
  use LivedjWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex">
      <.live_component
        id={"video_search_bar_#{@room.id}"}
        module={LivedjWeb.Components.SearchBarComponent}
        form={@search_form}
        search_result={@search_result}
      >
        <:button>
          <.button class="
            rounded-md
            cursor-default w-5 h-5 !p-0 flex flex-wrap justify-center content-center
            align-middle ml-2 bg-zinc-300 dark:bg-zinc-700
            transition-all duration-300
            shadow-[2.0px_2.0px_1px_0.5px_rgba(24,24,27,0.5)]
            hover:shadow-[1.5px_1.5px_1px_0.5px_rgba(24,24,27,0.9)]
            active:shadow-[0.5px_0.5px_1px_0.5px_rgba(24,24,27,0.2)]
            dark:shadow-[1.5px_1.5px_1px_0.5px_rgba(250,250,255,0.4)]
            dark:hover:shadow-[1.5px_1.5px_1px_0.5px_rgba(250,250,255,0.6)]
            dark:active:shadow-[0.5px_0.5px_1px_0.5px_rgba(250,250,255,0.2)]
            hover:bg-zinc-300 dark:hover:bg-zinc-700
            active:bg-zinc-200 dark:active:bg-zinc-800 group
            text-zinc-900 dark:text-zinc-100
            active:text-green-500 dark:active:text-green-500
          ">
            <.icon name="hero-plus" class="w-3 h-3" />
          </.button>
        </:button>
      </.live_component>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(
       player: to_form(%{}),
       search_form: to_form(%{}),
       search_result: []
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end
end
