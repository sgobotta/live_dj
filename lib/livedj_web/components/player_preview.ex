defmodule LivedjWeb.PlayerPreview do
  @moduledoc false

  use LivedjWeb, :live_component

  alias Livedj.Sessions.Player

  def render(assigns) do
    ~H"""
    <div class="song-cover-container relative h-40 w-40 py-2 px-2">
      <div
        :if={Livedj.Sessions.room_protected?(@room)}
        id={"room-lock-badge-#{@room.id}"}
        class="room-lock-badge absolute bottom-3 right-3 z-10 flex h-6 w-6 items-center justify-center rounded-full bg-tone-900/70 dark:bg-tone-50/70"
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
          class="h-full w-full rounded-md ring-0 ring-white"
          src={get_player_thumbnail(@player)}
        />
      <% else %>
        <div class={"
          h-full w-full rounded-md ring-0 ring-white bg-gray-200 dark:bg-gray-800
          flex flex-wrap justify-center content-center
          #{if paused?(@player), do: "animate-pulse"}
        "}>
          <.icon name="hero-musical-note" class="h-12 w-12 text-zinc-500" />
        </div>
      <% end %>
    </div>
    """
  end

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
