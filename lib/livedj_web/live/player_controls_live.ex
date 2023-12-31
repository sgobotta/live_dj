defmodule LivedjWeb.PlayerControlsLive do
  use LivedjWeb, {:live_view, layout: false}

  alias Livedj.Sessions
  alias Livedj.Sessions.{Player, Room}

  @on_play_click "on_play_click"
  @on_pause_click "on_pause_click"

  def render(assigns) do
    ~H"""
    <%= if connected?(@socket) do %>
      <%= if @player do %>
        <div
          id={@player_controls_id}
          class="
            bg-zinc-100 dark:bg-zinc-900
            border-t-[1px] border-zinc-300 dark:border-zinc-700
            h-24
          "
        >
          <div class="grid grid-cols-12 grid-rows-2 py-1 text-sm justify-center">
            <div class="col-span-3 row-span-2">
              <%!-- <div class="h-12 w-12 rounded-lg ring-2 ring-white m-1">
                <img
                  class="h-12 w-12 rounded-md ring-2 ring-white"
                  src="https://i.ytimg.com/vi/oCcks-fwq2c/default.jpg"
                />
              </div> --%>
            </div>
            <div class="col-span-6 row-span-1 w-full flex justify-center">
              <div class="flex items-center gap-4 h-12">
                <a phx-click="previous" class="cursor-pointer">
                  <.icon
                    name="hero-backward-solid"
                    class="h-7 w-7 text-zinc-700 hover:text-zinc-500 dark:text-zinc-300 dark:hover:bg-zinc-50"
                  />
                </a>
                <%= if @player && @player.state in [:playing] do %>
                  <a phx-click={on_pause_click_event()} class="cursor-pointer">
                    <.icon
                      name="hero-pause-circle-solid"
                      class="h-10 w-10 text-zinc-700 hover:scale-[1.1] dark:text-zinc-50"
                    />
                  </a>
                <% end %>
                <%= if @player && @player.state in [:idle, :paused] do %>
                  <a phx-click={on_play_click_event()} class="cursor-pointer">
                    <.icon
                      name="hero-play-circle-solid"
                      class="h-10 w-10 text-zinc-700 hover:scale-[1.1] dark:text-zinc-50"
                    />
                  </a>
                <% end %>
                <a phx-click="next" class="cursor-pointer">
                  <.icon
                    name="hero-forward-solid"
                    class="h-7 w-7 text-zinc-700 hover:text-zinc-500 dark:text-zinc-300 dark:hover:bg-zinc-50"
                  />
                </a>
              </div>
            </div>
            <div class="col-span-6 row-span-1 w-full flex justify-center">
              <div class="flex items-center justify-center p-2 h-12 w-full text-[0.525rem] text-zinc-600 dark:text-zinc-400 cursor-default">
                <div class="inline-flex items-center justify-center pl-2 w-10">
                  <span id={@start_time_tracker_id} class="video-time-tracker">
                    0:00
                  </span>
                </div>
                <form class="slider-form w-full p-4">
                  <input
                    class="seek-bar w-full"
                    id={@time_slider_id}
                    value="0"
                    type="range"
                    min="0"
                    max="100"
                    step="1"
                  />
                </form>
                <div class="inline-flex items-center justify-center pr-2 w-10">
                  <span id={@end_time_tracker_id} class="video-time-tracker">
                    0:00
                  </span>
                </div>
              </div>
            </div>
            <div class="col-span-3 row-span-2"></div>
          </div>
        </div>
      <% end %>
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
           start_time_tracker_id: "player-controls-start-time-tracker",
           end_time_tracker_id: "player-controls-end-time-tracker",
           time_slider_id: "player-controls-time-slider",
           layout: false,
           player: nil,
           room: room
         )}

      false ->
        {:ok,
         assign(socket,
           player: nil,
           start_time_tracker_id: nil,
           end_time_tracker_id: nil,
           time_slider_id: nil
         )}
    end
  end

  def update(_assigns, socket) do
    {:ok, socket}
  end

  def handle_event(@on_play_click, _params, socket) do
    {:noreply,
     push_event(socket, "request_current_time", %{
       callback_event: "on_player_play"
     })}
  end

  def handle_event(@on_pause_click, _params, socket) do
    {:noreply,
     push_event(socket, "request_current_time", %{
       callback_event: "on_player_pause"
     })}
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

  defp on_play_click_event, do: @on_play_click
  defp on_pause_click_event, do: @on_pause_click
end
