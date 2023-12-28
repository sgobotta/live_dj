defmodule LivedjWeb.PlayerControlsLive do
  use LivedjWeb, {:live_view, layout: false}

  alias Livedj.Sessions
  alias Livedj.Sessions.{Player, Room}

  def render(assigns) do
    ~H"""
    <%= if @player do %>
      <div
        id={@player_controls_id}
        class="
          bg-zinc-100 dark:bg-zinc-900
          border-t-[1px] border-zinc-300 dark:border-zinc-700
          h-16
        "
      >
        <div class="grid grid-cols-12 py-1 text-sm justify-center">
          <div class="col-span-3">
            <%!-- <div class="h-12 w-12 rounded-lg ring-2 ring-white m-1">
              <img
                class="h-12 w-12 rounded-md ring-2 ring-white"
                src="https://i.ytimg.com/vi/oCcks-fwq2c/default.jpg"
              />
            </div> --%>
          </div>
          <div class="col-span-6 justify-self-center">
            <div class="flex items-center gap-4 h-12">
              <a phx-click="previous" class="cursor-pointer">
                <.icon
                  name="hero-chevron-left-solid"
                  class="h-7 w-7 text-zinc-900 dark:text-zinc-100"
                />
              </a>
              <%= if @player && @player.state in [:playing] do %>
                <a phx-click="pause" class="cursor-pointer">
                  <.icon
                    name="hero-pause"
                    class="h-7 w-7 text-zinc-900 dark:text-zinc-100"
                  />
                </a>
              <% end %>
              <%= if @player && @player.state in [:idle, :paused] do %>
                <a phx-click="play" class="cursor-pointer">
                  <.icon
                    name="hero-play"
                    class="h-7 w-7 text-zinc-900 dark:text-zinc-100"
                  />
                </a>
              <% end %>
              <a phx-click="next" class="cursor-pointer">
                <.icon
                  name="hero-chevron-right-solid"
                  class="h-7 w-7 text-zinc-900 dark:text-zinc-100"
                />
              </a>
            </div>
          </div>
          <div class="col-span-3"></div>
        </div>
      </div>
    <% end %>
    """
  end

  def mount(params, _session, socket) do
    case connected?(socket) do
      true ->
        %Room{id: room_id} = room = Sessions.get_room!(params["id"])
        {:ok, :joined} = Sessions.join_player(room_id)

        {:ok,
         assign(socket,
           player_controls_id: "player-controls-#{Ecto.UUID.generate()}",
           layout: false,
           player: nil,
           room: room
         )}

      false ->
        {:ok, assign(socket, player: nil)}
    end
  end

  def update(_assigns, socket) do
    {:ok, socket}
  end

  def handle_event("play", _params, socket) do
    :ok = Sessions.play(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("pause", _params, socket) do
    :ok = Sessions.pause(socket.assigns.room.id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("previous", _params, socket) do
    Sessions.previous_track(socket.assigns.room.id)
    {:noreply, socket}
  end

  def handle_event("next", _params, socket) do
    Sessions.next_track(socket.assigns.room.id)
    {:noreply, socket}
  end

  # ----------------------------------------------------------------------------
  # Player event handling
  #

  def handle_info(
        {:player_joined, _room_id, %{player: %Sessions.Player{} = player}},
        socket
      ) do
    JS.transition({"ease-out duration-1000", "opacity-0", "opacity-100"},
      to: "##{socket.assigns.player_controls_id}"
    )

    {:noreply, assign_player(socket, player)}
  end

  def handle_info(
        {:player_state_changed, room_id, %Player{}},
        %{assigns: %{room: %Room{id: room_id}}} = socket
      ) do
    {:noreply, socket}
  end

  def handle_info(
        {:player_load_media, _room_id, %Sessions.Player{} = player},
        socket
      ) do
    {:noreply, assign_player(socket, player)}
  end

  def handle_info({:player_play, %Player{} = player}, socket) do
    {:noreply, assign_player(socket, player)}
  end

  def handle_info({:player_pause, %Player{} = player}, socket) do
    {:noreply, assign_player(socket, player)}
  end

  @spec assign_player(Phoenix.LiveView.Socket.t(), Sessions.Player.t()) ::
          Phoenix.LiveView.Socket.t()
  defp assign_player(socket, player), do: assign(socket, :player, player)
end
