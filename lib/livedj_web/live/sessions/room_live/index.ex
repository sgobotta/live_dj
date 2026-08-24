defmodule LivedjWeb.Sessions.RoomLive.Index do
  @moduledoc false
  use LivedjWeb, :live_view

  alias Livedj.Accounts
  alias Livedj.Presence
  alias Livedj.Sessions
  alias Livedj.Sessions.{Channels, Room}

  @impl true
  def mount(_params, _session, socket) do
    case connected?(socket) do
      true ->
        rooms = Sessions.list_rooms()

        for %Room{id: room_id} <- rooms do
          {:ok, :joined} = Sessions.join_player(room_id)
          :ok = Channels.subscribe_presence_topic(room_id)
        end

        rooms_players =
          Enum.map(rooms, fn %Room{id: room_id} = room ->
            %{
              id: room_id,
              room: room,
              player: nil,
              users: Presence.list_users(room_id)
            }
          end)

        {:ok, assign_rooms_players(socket, rooms_players)}

      false ->
        {:ok, socket}
    end
  end

  @doc """
  Splits the room/player entries into the featured (hero) room and the rest.

  The featured room is the one with the most present users; ties (including the
  case where every room is empty) are broken by the newest room, so the hero is
  always deterministic and never an awkward empty room when livelier ones exist.
  """
  @spec featured_and_rest([map()]) :: {map() | nil, [map()]}
  def featured_and_rest([]), do: {nil, []}

  def featured_and_rest(rooms_players) do
    featured = Enum.max_by(rooms_players, &featured_sort_key/1)
    rest = Enum.reject(rooms_players, &(&1.id == featured.id))
    {featured, rest}
  end

  @doc """
  Sorts room entries by number of present users, descending.

  Uses a stable sort, so rooms with an equal user count keep their existing
  relative order instead of jittering on every presence update.
  """
  @spec sort_by_users([map()]) :: [map()]
  def sort_by_users(rooms_players) do
    Enum.sort_by(rooms_players, &length(&1.users), :desc)
  end

  defp featured_sort_key(%{users: users, room: %Room{inserted_at: inserted_at}}) do
    # ISO8601 sorts lexicographically in chronological order, so a plain tuple
    # comparison yields "most users, then newest".
    {length(users), NaiveDateTime.to_iso8601(inserted_at)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("save_username", %{"username" => username}, socket) do
    case Accounts.update_user_username(socket.assigns.current_user, %{
           "username" => username
         }) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(:current_user, updated_user)
         |> put_flash(:info, gettext("Settings updated"))
         |> push_patch(to: ~p"/sessions/rooms/settings/general")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, username_error_message(changeset))}
    end
  end

  defp username_error_message(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn error ->
      LivedjWeb.CoreComponents.translate_error(error)
    end)
    |> Map.get(:username, [])
    |> Enum.join(", ")
    |> case do
      "" -> gettext("Invalid username")
      message -> message
    end
  end

  @impl true
  def handle_info(
        {LivedjWeb.Sessions.RoomLive.FormComponent,
         {:saved, %Room{id: room_id} = room}},
        socket
      ) do
    {:ok, :joined} = Sessions.join_player(room_id)
    :ok = Channels.subscribe_presence_topic(room_id)

    {:noreply,
     assign_rooms_players(
       socket,
       socket.assigns.rooms_players ++
         [%{id: room_id, room: room, player: nil, users: []}]
     )}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "presence_diff",
          topic: "room_presence:" <> room_id
        },
        socket
      ) do
    {:noreply, assign_users_by_room_id(socket, room_id)}
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

  defp apply_action(socket, :settings_general, _params) do
    socket
    |> assign(:page_title, gettext("Settings"))
    |> assign(:room, nil)
  end

  defp apply_action(socket, :settings_appearance, _params) do
    socket
    |> assign(:page_title, gettext("Settings"))
    |> assign(:room, nil)
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

    assign_rooms_players(socket, rooms_players)
  end

  defp assign_users_by_room_id(socket, room_id) do
    users = Presence.list_users(room_id)

    rooms_players =
      Enum.map(socket.assigns.rooms_players, fn
        %{id: ^room_id} = room_player ->
          Map.put(room_player, :users, users)

        room_player ->
          room_player
      end)

    assign_rooms_players(socket, rooms_players)
  end

  @doc false
  # Now-playing helpers used by the index/hero templates. Only a *playing*
  # player surfaces track text; idle/paused rooms show a muted idle label.
  def playing?(%{player: %Sessions.Player{state: :playing}}), do: true
  def playing?(_entry), do: false

  def now_playing_title(%{
        player: %Sessions.Player{state: :playing, title: title}
      })
      when is_binary(title) and title != "",
      do: title

  def now_playing_title(_entry), do: nil

  def now_playing_artist(%{
        player: %Sessions.Player{state: :playing, channel: channel}
      })
      when is_binary(channel) and channel != "",
      do: channel

  def now_playing_artist(_entry), do: nil

  def cover_url(%{player: %Sessions.Player{media_thumbnail_url: url}})
      when is_binary(url) and url != "",
      do: url

  def cover_url(_entry), do: nil

  defp assign_rooms_players(socket, rooms_players) do
    {featured, rest} = featured_and_rest(rooms_players)

    socket
    |> assign(:rooms_players, rooms_players)
    |> assign(:featured, featured)
    |> assign(:rest, sort_by_users(rest))
  end
end
