defmodule LivedjWeb.Components.PlayerControls.FullscreenControlComponent do
  @moduledoc false

  use LivedjWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative group">
      <.link
        id="fullscreen-btn"
        phx-click={unless @disabled?, do: "on_click"}
        phx-target={@myself}
        tabindex="0"
        aria-disabled={@disabled?}
        class={[
          "inline-flex items-center justify-center rounded focus:outline-none focus-ignite",
          @disabled? && "opacity-40 pointer-events-none cursor-not-allowed"
        ]}
      >
        {PhoenixInlineSvg.Helpers.svg_image(
          LivedjWeb.Endpoint,
          "fullscreen",
          "icons/misc",
          class: "
              h-5 w-5 stroke-2 cursor-pointer
              fill-tone-700 hover:fill-tone-900 focus:fill-tone-700 active:fill-tone-700
              dark:fill-tone-300 dark:hover:fill-tone-50 dark:focus:fill-tone-300 dark:active:fill-tone-300
              scale-100 hover:scale-[1.1] focus:scale-100 active:scale-100
            "
        )}
      </.link>
      <.tooltip :if={!@disabled?} class="left-1/2 -translate-x-[85%]">
        {gettext("Fullscreen")} (F)
      </.tooltip>
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
