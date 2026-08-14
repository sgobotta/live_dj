defmodule LivedjWeb.Components.PlayerControls.VolumeControlComponent do
  @moduledoc false

  use LivedjWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="
      inline-flex
      md:w-28 w-6
      fill-tone-700 hover:fill-tone-900 focus:fill-tone-700 active:fill-tone-700
      dark:fill-tone-300 dark:hover:fill-tone-50 dark:focus:fill-tone-300 dark:active:fill-tone-300
    ">
      <div class="relative group">
        <.button
          id="volume-mute-btn"
          tabindex="0"
          class={volume_button_class(@muted?)}
          aria-pressed={@muted?}
          phx-click="on_volume_click"
          phx-target={@myself}
        >
          {PhoenixInlineSvg.Helpers.svg_image(
            LivedjWeb.Endpoint,
            get_volume_icon(@muted?, @level),
            "icons/volume",
            class: "h-6 w-6 p-1"
          )}
        </.button>
        <.tooltip>
          {if @muted?,
            do: "#{gettext("Unmute")} (M)",
            else: "#{gettext("Mute")} (M)"}
        </.tooltip>
      </div>
      <div class="ml-2 flex-1 min-w-0 self-center hidden md:block">
        <.form
          :let={f}
          for={@player}
          id="volume-controls-slider"
          class="w-full"
          phx-target={@myself}
          phx-change="on_volume_change"
        >
          <div class="custom-slider">
            <.input
              field={f[:volume]}
              class="custom-slider-input"
              id="volume-slider"
              phx-hook="RangeSlider"
              value={if @muted?, do: 0, else: @level}
              type="range"
              min="0"
              max="100"
              step="5"
              phx-debounce={500}
              phx-value-key="volume"
            />
            <div class="custom-slider-track">
              <div class="custom-slider-fill"></div>
              <div class="custom-slider-thumb"></div>
            </div>
          </div>
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
  def handle_event(
        "on_volume_click",
        _params,
        %{assigns: %{muted?: muted?}} = socket
      ) do
    {:noreply,
     socket
     |> assign(muted?: !muted?)
     |> push_event(if(muted?, do: "unmute", else: "mute"), %{})}
  end

  @impl true
  def handle_event("on_volume_change", %{"volume" => volume}, socket) do
    {:noreply,
     socket
     |> assign(
       level: String.to_integer(volume),
       muted?: false
     )
     |> push_event("change_volume", %{volume_level: volume})}
  end

  defp volume_button_class(muted?) do
    [
      "focus-visible:ring-2 focus-visible:ring-tone-900 focus-visible:dark:ring-tone-50",
      "rounded-md",
      "cursor-pointer w-6 h-6 !p-0 flex flex-wrap justify-center content-center",
      "align-middle transition-all duration-300 group",
      "hover:shadow-[1.5px_1.5px_1px_0.5px_rgba(24,24,27,0.9)]",
      "active:shadow-[0.5px_0.5px_1px_0.5px_rgba(24,24,27,0.2)]",
      "dark:hover:shadow-[1.5px_1.5px_1px_0.5px_rgba(250,250,255,0.6)]",
      "dark:active:shadow-[0.5px_0.5px_1px_0.5px_rgba(250,250,255,0.2)]",
      "hover:bg-tone-300 dark:hover:bg-tone-700",
      "active:bg-tone-200 dark:active:bg-tone-800",
      "active:text-green-500 dark:active:text-green-500",
      muted_state_class(muted?)
    ]
    |> Enum.join(" ")
  end

  defp muted_state_class(true) do
    """
    fill-red-500
    bg-tone-200 dark:bg-tone-800
    text-green-500 dark:text-green-500
    shadow-[0.5px_0.5px_1px_0.5px_rgba(24,24,27,0.2)]
    dark:shadow-[0.5px_0.5px_1px_0.5px_rgba(250,250,255,0.2)]
    """
  end

  defp muted_state_class(_muted?) do
    """
    fill-tone-900 dark:fill-tone-50
    bg-tone-300 dark:bg-tone-700
    text-tone-900 dark:text-tone-100
    shadow-[2.0px_2.0px_1px_0.5px_rgba(24,24,27,0.5)]
    dark:shadow-[1.5px_1.5px_1px_0.5px_rgba(250,250,255,0.4)]
    """
  end

  defp get_volume_icon(true, _volume_level) do
    "speaker-0"
  end

  defp get_volume_icon(_muted?, volume_level) do
    get_volume_icon_by_volume_level(volume_level)
  end

  defp get_volume_icon_by_volume_level(0), do: "speaker-0"

  defp get_volume_icon_by_volume_level(volume) when volume <= 10,
    do: "speaker-1"

  defp get_volume_icon_by_volume_level(volume) when volume <= 30,
    do: "speaker-2"

  defp get_volume_icon_by_volume_level(volume) when volume <= 70,
    do: "speaker-3"

  defp get_volume_icon_by_volume_level(_volume), do: "speaker-4"
end
