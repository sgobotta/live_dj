defmodule LiveDjWeb.Components.Settings.RoomSettings do
  @moduledoc """
  Responsible for displaying the room settings
  """

  use LiveDjWeb, :live_component

  alias LiveDj.Organizer.Room
  alias LiveDj.Repo

  def update(assigns, socket) do
    %{user_room_group: %{permissions: permissions}, room_management: room_management} = assigns

    is_managed = room_management != "free"

    legacy_room_details_permissions = %{
      can_edit_room_management_type: has_permission(permissions, "can_edit_room_management_type"),
      can_edit_room_name: has_permission(permissions, "can_edit_room_name")
    }

    room_details_permissions = %{
      can_edit_room_management_type:
        !is_managed or
          has_permission(
            permissions,
            "can_edit_room_management_type"
          ),
      can_edit_room_name:
        !is_managed or
          has_permission(
            permissions,
            "can_edit_room_name"
          )
    }

    {_, has_all_room_permissions} =
      Enum.map_reduce(room_details_permissions, true, fn {_key, has_permission}, acc ->
        {has_permission, acc and has_permission}
      end)

    {:ok,
     socket
     |> assign(:changeset, assigns.room_changeset)
     |> assign(:has_all_room_permissions, has_all_room_permissions)
     |> assign(:is_managed, is_managed)
     |> assign(
       :legacy_room_details_permissions,
       legacy_room_details_permissions
     )
     |> assign(:slug, assigns.room_changeset.data.slug)}
  end

  defp has_permission(permissions, permission) do
    Enum.any?(permissions, fn p -> p.codename == permission end)
  end

  def handle_event("validate", _params, %{assigns: %{has_all_room_permissions: false}} = socket) do
    {:noreply,
     socket
     # FIXME: use gettext
     |> put_flash(:error, "You don't have enough permissions to edit the room.")}
  end

  def handle_event("validate", %{"room" => room_params}, socket) do
    {:noreply,
     socket
     |> assign_changeset(socket.assigns.changeset, room_params)}
  end

  def handle_event("submit_changeset", _, %{assigns: %{has_all_room_permissions: false}} = socket) do
    {:noreply,
     socket
     # FIXME: use gettext
     |> put_flash(:error, "You don't have enough permissions to edit the room.")}
  end

  def handle_event("submit_changeset", _, %{assigns: %{has_all_room_permissions: true}} = socket) do
    %{assigns: %{changeset: changeset}} = socket

    case Repo.update(changeset) do
      {:ok, room} ->
        :ok =
          Phoenix.PubSub.broadcast(
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
