defmodule LiveDjWeb.Room.NewLive do
  use LiveDjWeb, :live_view

  alias LiveDj.Repo
  alias LiveDj.Organizer
  alias LiveDj.Organizer.Room
  alias LiveDj.Organizer.Queue

  @tick_rate :timer.seconds(15)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Organizer.subscribe()
      :timer.send_interval(1000, self(), :reload_room_list)
    end

    public_rooms = Organizer.list_rooms()

    rooms_players = for room <- public_rooms do
      {String.to_atom(room.slug), nil}
    end
    rooms_queues = for room <- public_rooms, do: {String.to_atom(room.slug), []}
    viewers_quantity = for room <- public_rooms do
      {String.to_atom(room.slug), Organizer.viewers_quantity(room)}
    end

    socket =
      socket
      |> assign(:public_rooms, public_rooms)
      |> assign(:rooms_players, rooms_players)
      |> assign(:rooms_queues, rooms_queues)
      |> assign(:viewers_quantity, viewers_quantity)
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

  def handle_event("save", _, %{assigns: %{changeset: changeset}} = socket) do
    case Repo.insert(changeset) do
      {:ok, room} ->
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
