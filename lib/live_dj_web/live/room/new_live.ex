defmodule LiveDjWeb.Room.NewLive do
  use LiveDjWeb, :live_view

  alias LiveDj.Accounts
  alias LiveDj.Collections
  alias LiveDj.ConnectedUser
  alias LiveDj.Notifications
  alias LiveDj.Organizer
  alias LiveDj.Organizer.Room
  alias LiveDj.Organizer.Queue
  alias LiveDj.Repo
  alias LiveDj.Stats

  require Logger

  @tick_rate :timer.seconds(15)

  @impl true
  def mount(params, session, socket) do
    if connected?(socket) do
      Organizer.subscribe()
      :timer.send_interval(1000, self(), :reload_room_list)
    end
    socket = assign_defaults(socket, params, session)
    %{current_user: current_user, visitor: visitor} = socket.assigns
    user = ConnectedUser.create_connected_user(current_user.username)

    public_rooms = Organizer.list_rooms()

    rooms_players = for room <- public_rooms do
      {String.to_atom(room.slug), nil}
    end
    rooms_queues = for room <- public_rooms do
      {String.to_atom(room.slug), room.queue}
    end
    viewers_quantity = for room <- public_rooms do
      {String.to_atom(room.slug), Organizer.viewers_quantity(room)}
    end

    options = ["Free room management for everyone": "free"]

    management_type_options = case visitor do
      true -> options
      false -> options ++ [
        "Anyone can join, but it's managed by admin and collaborators": "managed"
      ]
    end

    socket =
      socket
      |> assign(:management_type_options, management_type_options)
      |> assign(:user, user)
      |> assign(:public_rooms, public_rooms)
      |> assign(:rooms_players, rooms_players)
      |> assign(:rooms_queues, rooms_queues)
      |> assign(:viewers_quantity, viewers_quantity)
      |> assign(:visitor, visitor)
      |> put_changeset()

    send(self(), :tick)

    {:ok, socket}
  end

  @impl true
  def handle_info(:reload_room_list, socket) do
    socket =
      update(
        socket,
        :viewers_quantity,
        fn _viewers_quantity ->
          for room <- socket.assigns.public_rooms do
            {String.to_atom(room.slug), Organizer.viewers_quantity(room)}
          end
        end
      )
    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    %{assigns: %{public_rooms: public_rooms}} = socket
    schedule_next_tick()

    request_rooms_player(public_rooms)

    {:noreply, socket}
  end

  def handle_info({:receive_current_player, %{slug: slug} = params}, socket) do
    Organizer.unsubscribe(:request_current_player, slug)
    %{assigns: %{
      rooms_players: rooms_players, rooms_queues: rooms_queues}} = socket

    current_slug = String.to_atom(slug)
    %{player: player, video_queue: video_queue} = params

    rooms_players = case player.state do
      "stopped" ->
        rooms_players
      _ ->
        current_track = Enum.map(video_queue, fn {v, _} -> v end)
        |> Queue.get_video_by_id(player.video_id)

        for player <- rooms_players do
          {slug, player} = player
          case slug do
            ^current_slug -> {current_slug, current_track}
            slug -> {slug, player}
          end
        end
    end

    rooms_queues = for queue <- rooms_queues do
      {slug, queue} = queue
      case slug do
        ^current_slug -> {current_slug, video_queue}
        slug -> {slug, queue}
      end
    end

    {:noreply,
      socket
      |> assign(:public_rooms, Organizer.list_rooms())
      |> assign(:rooms_players, rooms_players)
      |> assign(:rooms_queues, rooms_queues)}
  end

  @impl true
  def handle_event("validate", %{"room" => room_params}, socket) do
    {:noreply,
      socket
      |> put_changeset(room_params)
    }
  end

  def handle_event("save", _,
    %{
      assigns: %{
      visitor: true,
      changeset: %{changes: %{management_type: "managed"}} = changeset
      }
    } = socket
  ) do
    {:noreply,
      socket
      |> assign(:changeset, changeset)
      |> put_flash(:error,
        "Please sign in with a username to create managed rooms."
      )
    }
  end

  def handle_event("save", _, %{assigns: assigns} = socket) do
    %{
      changeset: changeset,
      current_user: current_user,
      visitor: visitor
    } = assigns

    # Move to a controller and refactor to an Organizer context
    case Repo.insert(changeset) do
      {:ok, room} ->
        {:ok, playlist} = Collections.create_playlist()
        {:ok, room} = Organizer.assoc_playlist(room, playlist)
        {socket, room} = case visitor do
          true -> {socket, room}
          false ->
            group = Accounts.get_group_by_codename("room-admin")
            {:ok, _user_room} = Organizer.create_user_room(%{
              room_id: room.id,
              user_id: current_user.id,
              group_id: group.id,
              is_owner: true
            })
            rooms_length = length(Accounts.preload_user(current_user, [:rooms]).rooms)
            socket = case Stats.assoc_user_badge("rooms-creation", current_user.id, rooms_length) do
              {:ok, user_badge} ->
                %{badge: badge} = user_badge
                # FIXME: Not received. Maybe cause a redirection is performed.
                push_event(socket, "receive_notification", Notifications.create(
                  :receive_badge, %{
                    badge_icon: badge.icon,
                    badge_name: badge.name
                  }
                ))
              {:unchanged} -> socket
              {:error} -> socket
            end
            {socket, room}
        end
        {:noreply,
          socket
          |> redirect(to: Routes.show_path(socket, :show, room.slug))
        }
      {:error, changeset} ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)
          |> put_flash(:error, "Could not save the room.")
        }
    end
  end

  def handle_event("redirect_room", %{"slug" => slug}, socket) do
    {:noreply,
      socket
      |> redirect(to: Routes.show_path(socket, :show, slug))}
  end

  defp put_changeset(socket, params \\ %{}) do
    socket
    |> assign(:changeset, Room.changeset(%Room{}, params))
  end

  defp schedule_next_tick() do
    Process.send_after(self(), :tick, @tick_rate)
  end

  defp request_rooms_player(rooms) do

    for room <- rooms do
      %{slug: slug} = room
      Organizer.subscribe(:request_current_player, slug)
      :ok = Phoenix.PubSub.broadcast_from(
        LiveDj.PubSub,
        self(),
        "room:" <> slug,
        {:request_current_player, %{}}
      )
    end
  end
end
