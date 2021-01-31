defmodule LiveDjWeb.Components.Settings.RoomSettings do
  @moduledoc """
  Responsible for displaying the room settings
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Organizer.Room
  alias LiveDj.Repo

  def update(assigns, socket) do
    {:ok,
      socket
      |> assign(:changeset, assigns.room_changeset)
      |> assign(:slug, assigns.room_changeset.data.slug)
    }
  end

  def handle_event("validate", %{"room" => room_params}, socket) do
    {:noreply,
      socket
      |> assign_changeset(socket.assigns.changeset, room_params)}
  end

  def handle_event("submit_changeset", _, socket) do
    %{assigns: %{changeset: changeset}} = socket
    case Repo.update(changeset) do
      {:ok, room} ->
        :ok = Phoenix.PubSub.broadcast(
          LiveDj.PubSub,
          "room:" <> room.slug,
          {:update_room_assign, %{room: room}}
        )
        {:noreply,
          socket
          |> put_flash(:info, "Room updated succesfully!")}
      {:error, changeset} ->
        {:noreply,
          socket
          |> assign(:changeset, changeset)
          |> put_flash(:error, "Could not save the room.")}
    end
  end

  defp assign_changeset(socket, changeset, params) do
    assign(socket, :changeset, Room.changeset(changeset, params))
  end
end
