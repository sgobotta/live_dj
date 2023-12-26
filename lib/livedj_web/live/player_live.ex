defmodule LivedjWeb.PlayerLiveView do
  use LivedjWeb, {:live_view, layout: false}

  def render(assigns) do
    ~H"""
    <div
      id={@player_id}
      class="w-full h-72 rounded-lg transition duration-1000 hidden mr-1"
    />
    """
  end

  def mount(_params, %{"player_id" => player_id}, socket) do
    {:ok,
     socket
     |> assign(:player_id, player_id)
     |> assign(layout: false)}
  end

  def update(_assigns, socket) do
    {:ok, socket}
  end
end
