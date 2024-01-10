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
            h-26
          "
        >
          <div class="grid grid-cols-12 grid-rows-2 py-1 text-sm justify-center">
            <div class="col-span-3 row-span-2 self-center pl-2">
              <div class="flex">
                <div class="
                  basis-28 sm:basis-28 md:basis-28 lg:basis-24 xl:basis-24 2xl:basis-24
                  h-16 w-16 ring-0 ring-white m-1">
                  <%= if @player.media_thumbnail_url != "" do %>
                    <img
                      class="h-16 w-16 rounded-md ring-0 ring-white"
                      src={@player.media_thumbnail_url}
                    />
                  <% else %>
                    <div class="h-16 w-16 rounded-md ring-0 ring-white bg-gray-200 dark:bg-gray-800 animate-pulse" />
                  <% end %>
                </div>
                <div class="
                  md:flex md:flex-col hidden
                  basis-full justify-center
                  h-16 ring-0 ring-white m-1
                  cursor-default
                ">
                  <%= if media_loaded?(@player.media_id) do %>
                    <p class="text-zinc-900 dark:text-zinc-100 font-semibold text-sm overflow-hidden text-ellipsis h-5">
                      <%= @player.title %>
                    </p>
                    <p class="text-zinc-700 dark:text-zinc-300 font-normal text-xs overflow-hidden text-ellipsis h-5">
                      <%= @player.channel %>
                    </p>
                  <% else %>
                    <div class="flex flex-col gap-2">
                      <div class="h-5 w-full bg-gray-200 dark:bg-gray-800 rounded animate-pulse">
                      </div>
                      <div class="h-5 w-full bg-gray-200 dark:bg-gray-800 rounded animate-pulse">
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
            <div class="col-span-6 row-span-1 w-full flex justify-center items-center">
              <div class="flex items-center gap-4 h-10">
                <a phx-click="previous" class="cursor-pointer">
                  <.icon
                    name="hero-backward-solid"
                    class="h-5 w-5 text-zinc-700 hover:text-zinc-500 dark:text-zinc-300 dark:hover:bg-zinc-50"
                  />
                </a>
                <%= if @player && @player.state in [:playing] do %>
                  <a phx-click={on_pause_click_event()} class="cursor-pointer">
                    <.icon
                      name="hero-pause-circle-solid"
                      class="h-8 w-8 text-zinc-700 hover:scale-[1.1] dark:text-zinc-50"
                    />
                  </a>
                <% end %>
                <%= if @player && @player.state in [:idle, :paused] do %>
                  <a phx-click={on_play_click_event()} class="cursor-pointer">
                    <.icon
                      name="hero-play-circle-solid"
                      class="h-8 w-8 text-zinc-700 hover:scale-[1.1] dark:text-zinc-50"
                    />
                  </a>
                <% end %>
                <a phx-click="next" class="cursor-pointer">
                  <.icon
                    name="hero-forward-solid"
                    class="h-5 w-5 text-zinc-700 hover:text-zinc-500 dark:text-zinc-300 dark:hover:bg-zinc-50"
                  />
                </a>
              </div>
            </div>
            <div
              class="col-span-6 row-span-1 w-full flex justify-center"
              id="seek-bar-container"
              phx-update="ignore"
            >
              <div class="flex items-center justify-center h-12 w-full text-[0.525rem] text-zinc-600 dark:text-zinc-400 cursor-default">
                <div class="inline-flex items-center justify-center pl-2 w-10">
                  <span id={@start_time_tracker_id}>
                    <%= render_default_seek_bar_value() %>
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
                  <span id={@end_time_tracker_id}>
                    <%= render_default_seek_bar_value() %>
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

  defp render_default_seek_bar_value, do: "0:00"

  defp media_loaded?(""), do: false
  defp media_loaded?(_media_id), do: true
end
