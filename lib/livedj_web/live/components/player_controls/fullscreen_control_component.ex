defmodule LivedjWeb.Components.PlayerControls.FullscreenControlComponent do
  @moduledoc false

  use LivedjWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-click="on_click" phx-target={@myself}>
      <%= PhoenixInlineSvg.Helpers.svg_image(
        LivedjWeb.Endpoint,
        "fullscreen",
        "icons/misc",
        class: "
            h-4 w-4 stroke-2 cursor-pointer
            fill-zinc-700 hover:fill-zinc-900 focus:fill-zinc-700 active:fill-zinc-700
            dark:fill-zinc-300 dark:hover:fill-zinc-50 dark:focus:fill-zinc-300 dark:active:fill-zinc-300
            scale-100 hover:scale-[1.1] focus:scale-100 active:scale-100
          "
      ) %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("on_click", _params, socket) do
    {:noreply, push_event(socket, "fullscreen", %{})}
  end
end
