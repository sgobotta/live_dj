defmodule LivedjWeb.Sessions.RoomLive.Index do
  @moduledoc false
  use LivedjWeb, :live_view

  alias Livedj.Sessions
  alias Livedj.Sessions.Room

  @impl true
  def mount(_params, _session, socket) do
    case connected?(socket) do
      true ->
        rooms = Sessions.list_rooms()

        for %Room{id: room_id} <- rooms do
          {:ok, :joined} = Sessions.join_player(room_id)
        end

        rooms_players =
          Enum.map(rooms, fn %Room{id: room_id} = room ->
            %{id: room_id, room: room, player: nil}
          end)

        {:ok, assign(socket, :rooms_players, rooms_players)}

      false ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(
        {LivedjWeb.Sessions.RoomLive.FormComponent,
         {:saved, %Room{id: room_id} = room}},
        socket
      ) do
    {:ok, :joined} = Sessions.join_player(room_id)

    {:noreply,
     assign(
       socket,
       :rooms_players,
       socket.assigns.rooms_players ++ [%{id: room_id, room: room, player: nil}]
     )}
  end

  # ----------------------------------------------------------------------------
  # Server side Player event handling
  #

  def handle_info(
        {:player_joined, room_id, %{player: %Sessions.Player{} = player}},
        socket
      ) do
    {:noreply, assign_player_by_room_id(socket, room_id, player)}
  end

  def handle_info(
        {:player_state_changed, room_id, %Sessions.Player{} = player},
        socket
      ) do
    {:noreply, assign_player_by_room_id(socket, room_id, player)}
  end

  def handle_info(
        {:player_load_media, room_id, %Sessions.Player{} = player},
        socket
      ) do
    {:noreply, assign_player_by_room_id(socket, room_id, player)}
  end

  def handle_info({:player_play, room_id, %Sessions.Player{} = player}, socket) do
    {:noreply, assign_player_by_room_id(socket, room_id, player)}
  end

  def handle_info({:player_pause, room_id, %Sessions.Player{} = player}, socket) do
    {:noreply, assign_player_by_room_id(socket, room_id, player)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("Listing Rooms"))
    |> assign(:room, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New Room"))
    |> assign(:room, %Room{})
  end

  defp assign_player_by_room_id(socket, room_id, player) do
    rooms_players =
      Enum.map(socket.assigns.rooms_players, fn
        %{id: ^room_id, room: %Room{id: ^room_id}, player: _maybe_player} =
            room_player ->
          Map.put(room_player, :player, player)

        room_player ->
          room_player
      end)

    assign(socket, :rooms_players, rooms_players)
  end
end
