defmodule LivedjWeb.PlayerPreview do
  @moduledoc false

  use LivedjWeb, :live_component

  alias Livedj.Sessions.Player

  attr :size, :atom,
    default: :md,
    doc: ":md renders a fluid square card cover, :lg a larger featured cover"

  def render(assigns) do
    ~H"""
    <div class={["song-cover-container relative", cover_size_class(@size)]}>
      <div
        :if={Livedj.Sessions.room_protected?(@room)}
        id={"room-lock-badge-#{@room.id}"}
        class="room-lock-badge absolute bottom-2 right-2 z-10 flex h-6 w-6 items-center justify-center rounded-full bg-tone-900/70 dark:bg-tone-50/70"
        title={gettext("Password protected")}
        aria-label={gettext("Password protected")}
      >
        <.icon
          name="hero-lock-closed"
          class="h-3.5 w-3.5 text-tone-50 dark:text-tone-900"
        />
      </div>
      <%= if player?(@player) && @player.media_thumbnail_url != "" do %>
        <img
          class="h-full w-full rounded-lg object-cover"
          src={get_player_thumbnail(@player)}
        />
      <% else %>
        <div class={[
          "h-full w-full rounded-lg bg-tone-200 dark:bg-tone-800",
          "flex flex-wrap justify-center content-center",
          paused?(@player) && "animate-pulse"
        ]}>
          <.icon name="hero-musical-note" class={placeholder_icon_class(@size)} />
        </div>
      <% end %>
    </div>
    """
  end

  defp cover_size_class(:lg), do: "aspect-square w-full sm:h-56 sm:w-56"
  defp cover_size_class(_md), do: "aspect-square w-full"

  defp placeholder_icon_class(:lg), do: "h-16 w-16 text-tone-500"
  defp placeholder_icon_class(_md), do: "h-12 w-12 text-tone-500"

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  defp player?(nil), do: false
  defp player?(%Player{}), do: true

  defp paused?(%Player{state: :paused}), do: true
  defp paused?(_player), do: false

  defp get_player_thumbnail(%Livedj.Sessions.Player{
         media_thumbnail_url: media_thumbnail_url
       }),
       do: media_thumbnail_url
end
