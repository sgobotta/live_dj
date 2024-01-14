defmodule LivedjWeb.Components.PlayerControls.VolumeControlComponent do
  @moduledoc false

  use LivedjWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="hidden sm:inline-flex w-24">
      <div class="m-2 ">
        <%= PhoenixInlineSvg.Helpers.svg_image(
          LivedjWeb.Endpoint,
          "speaker-4",
          "icons/volume",
          class: "
              h-5 w-5 stroke-2
              fill-zinc-700 hover:fill-zinc-500 active:fill-zinc-700 focus:fill-zinc-700
              dark:fill-zinc-300 dark:hover:fill-zinc-50 dark:active:fill-zinc-300 dark:focus:fill-zinc-300
            "
        ) %>
      </div>
      <div class="self-center">
        <.form
          :let={f}
          for={@player}
          id="volume-controls-slider"
          class="slider-form"
          phx-target={@myself}
          phx-change="on_volume_change"
        >
          <.input
            field={f[:volume]}
            class="seek-bar w-full !m-0 !bg-transparent"
            id="volume-slider"
            value={100}
            type="range"
            min="0"
            max="100"
            step="1"
            phx-debounce={500}
            phx-value-volume={get_volume(@player)}
          />
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(player: to_form(%{}))}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("on_volume_change", %{"volume" => _volume}, socket) do
    {:noreply, socket}
  end

  defp get_volume(_form) do
    100
  end
end
