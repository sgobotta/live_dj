defmodule LivedjWeb.Components.PlayerControls.VolumeControlComponent do
  @moduledoc false

  use LivedjWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="
      inline-flex
      md:w-28 w-5
      fill-zinc-700 hover:fill-zinc-900 focus:fill-zinc-700 active:fill-zinc-700
      dark:fill-zinc-300 dark:hover:fill-zinc-50 dark:focus:fill-zinc-300 dark:active:fill-zinc-300
    ">
      <.button
        tabindex="0"
        phx-key="m"
        phx-window-keydown="on_volume_click"
        class={volume_button_class(@muted?)}
        aria-pressed={@muted?}
        href="#"
        phx-click="on_volume_click"
        phx-target={@myself}
      >
        <%= PhoenixInlineSvg.Helpers.svg_image(
          LivedjWeb.Endpoint,
          get_volume_icon(@muted?, @level),
          "icons/volume",
          class: "h-6 w-6 p-1"
        ) %>
      </.button>
      <div class="ml-2 self-center hidden md:block">
        <.form
          :let={f}
          for={@player}
          id="volume-controls-slider"
          class=""
          phx-target={@myself}
          phx-change="on_volume_change"
        >
          <.input
            field={f[:volume]}
            class="seek-bar w-full !m-0 shadow-none !bg-transparent focus:ring-2 focus:ring-zinc-900 focus:dark:ring-zinc-50"
            id="volume-slider"
            value={if @muted?, do: 0, else: @level}
            type="range"
            min="0"
            max="100"
            step="5"
            phx-debounce={500}
            phx-value-key="volume"
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
      "focus-visible:ring-2 focus-visible:ring-zinc-900 focus-visible:dark:ring-zinc-50",
      "rounded-md",
      "cursor-pointer w-6 h-6 !p-0 flex flex-wrap justify-center content-center",
      "align-middle transition-all duration-300 group",
      "hover:shadow-[1.5px_1.5px_1px_0.5px_rgba(24,24,27,0.9)]",
      "active:shadow-[0.5px_0.5px_1px_0.5px_rgba(24,24,27,0.2)]",
      "dark:hover:shadow-[1.5px_1.5px_1px_0.5px_rgba(250,250,255,0.6)]",
      "dark:active:shadow-[0.5px_0.5px_1px_0.5px_rgba(250,250,255,0.2)]",
      "hover:bg-zinc-300 dark:hover:bg-zinc-700",
      "active:bg-zinc-200 dark:active:bg-zinc-800",
      "active:text-green-500 dark:active:text-green-500",
      muted_state_class(muted?)
    ]
    |> Enum.join(" ")
  end

  defp muted_state_class(true) do
    """
    fill-red-500
    bg-zinc-200 dark:bg-zinc-800
    text-green-500 dark:text-green-500
    shadow-[0.5px_0.5px_1px_0.5px_rgba(24,24,27,0.2)]
    dark:shadow-[0.5px_0.5px_1px_0.5px_rgba(250,250,255,0.2)]
    """
  end

  defp muted_state_class(_muted?) do
    """
    fill-zinc-900 dark:fill-zinc-50
    bg-zinc-300 dark:bg-zinc-700
    text-zinc-900 dark:text-zinc-100
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
