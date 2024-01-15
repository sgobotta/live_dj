defmodule LivedjWeb.Components.PlayerControls.VolumeControlComponent do
  @moduledoc false

  use LivedjWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="
      hidden sm:inline-flex w-24
      fill-zinc-700 hover:fill-zinc-900 focus:fill-zinc-700 active:fill-zinc-700
      dark:fill-zinc-300 dark:hover:fill-zinc-50 dark:focus:fill-zinc-300 dark:active:fill-zinc-300
    ">
      <div class="m-2" phx-click="on_volume_click" phx-target={@myself}>
        <%= PhoenixInlineSvg.Helpers.svg_image(
          LivedjWeb.Endpoint,
          get_volume_icon(@muted?, @level),
          "icons/volume",
          class: "
              h-5 w-5

            "
        ) %>
      </div>
      <div class="self-center">
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
            class="seek-bar w-full !m-0 shadow-none !bg-transparent"
            id="volume-slider"
            value={if @muted?, do: 0, else: @level}
            type="range"
            min="0"
            max="100"
            step="1"
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
