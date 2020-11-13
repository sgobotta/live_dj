defmodule LiveDjWeb.Room.NewLive do
  use LiveDjWeb, :live_view

  alias LiveDj.Repo
  alias LiveDj.Organizer
  alias LiveDj.Organizer.Room

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Organizer.subscribe()
      :timer.send_interval(1000, self(), :reload_room_list)
    end

    public_rooms = Organizer.list_rooms()
    viewers_quantity = for room <- public_rooms, do: {String.to_atom(room.title), Organizer.viewers_quantity(room)}

    socket =
      socket
      |> assign(:public_rooms, public_rooms)
      |> assign(:viewers_quantity, viewers_quantity)
      |> put_changeset()


    {:ok, socket}
  end

  @impl true
  def handle_info(:reload_room_list, socket) do
    socket =
      update(
        socket,
        :viewers_quantity,
        fn _viewers_quantity -> for room <- socket.assigns.public_rooms, do: {String.to_atom(room.title), Organizer.viewers_quantity(room)} end
      )
    {:noreply, socket}
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
end
