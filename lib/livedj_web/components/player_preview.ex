defmodule LivedjWeb.PlayerPreview do
  @moduledoc false

  use LivedjWeb, :live_component

  alias Livedj.Sessions.Player

  def render(assigns) do
    ~H"""
    <div class="h-40 w-40 py-2 px-2">
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
