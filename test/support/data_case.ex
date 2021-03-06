defmodule LiveDj.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use LiveDj.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias LiveDj.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import LiveDj.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(LiveDj.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(LiveDj.Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  import LiveDj.AccountsFixtures
  import LiveDj.OrganizerFixtures
  import LiveDj.StatsFixtures

  def groups_setup do
    # Creates some mandatory groups
    anonymous_room_visitor_group = group_fixture(%{
      codename: "anonymous-room-visitor",
      name: "Anonymous room visitor"
    })
    registered_room_visitor_group = group_fixture(%{
      codename: "registered-room-visitor",
      name: "Registered room visitor"
    })
    room_admin_group = group_fixture(%{
      codename: "room-admin",
      name: "Room admin"
    })
    room_collaborator_group = group_fixture(%{
      codename: "room-collaborator",
      name: "Room collaborator"
    })
    %{anonymous_room_visitor_group: anonymous_room_visitor_group,
      registered_room_visitor: registered_room_visitor_group,
      room_admin_group: room_admin_group,
      room_collaborator_group: room_collaborator_group}
  end

  def permissions_setup do
    # Creates some mandatory permissions
    can_add_room_collaborators_permission = permission_fixture(%{
      codename: "can_add_room_collaborators",
      name: "Can add room collaborators"
    })
    can_remove_room_collaborators_permission = permission_fixture(%{
      codename: "can_remove_room_collaborators",
      name: "Can remove room collaborators"
    })
    can_edit_room_management_type = permission_fixture(%{
      codename: "can_edit_room_management_type",
      name: "Can edit room management type"
    })
    can_edit_room_name = permission_fixture(%{
      codename: "can_edit_room_name",
      name: "Can edit room name"
    })
    can_play_track_permission = permission_fixture(%{
      codename: "can_play_track",
      name: "Can play tracks"
    })
    can_pause_track_permission = permission_fixture(%{
      codename: "can_pause_track",
      name: "Can pause tracks"
    })
    can_play_next_track_permission = permission_fixture(%{
      codename: "can_play_next_track",
      name: "Can play next track"
    })
    can_play_previous_track_permission = permission_fixture(%{
      codename: "can_play_previous_track",
      name: "Can play previous track"
    })

    %{can_add_room_collaborators_permission:
        can_add_room_collaborators_permission,
      can_remove_room_collaborators_permission:
        can_remove_room_collaborators_permission,
      can_edit_room_management_type_permission: can_edit_room_management_type,
      can_edit_room_name_permission: can_edit_room_name,
      can_play_track_permission: can_play_track_permission,
      can_pause_track_permission: can_pause_track_permission,
      can_play_next_track_permission: can_play_next_track_permission,
      can_play_previous_track_permission: can_play_previous_track_permission}
  end

  def badges_setup do
    badge_fixture(%{type: "rooms-collaboration", checkpoint: 1})
  end

  @doc """
  A helper that initialises the needed data for a show live view
  """
  def show_live_setup do
    %{room_admin_group: room_admin_group,
      room_collaborator_group: room_collaborator_group} = groups_setup()
    %{can_add_room_collaborators_permission:
        can_add_room_collaborators_permission,
      can_remove_room_collaborators_permission:
        can_remove_room_collaborators_permission,
      can_edit_room_management_type_permission:
        can_edit_room_management_type_permission,
      can_edit_room_name_permission: can_edit_room_name_permission,
      can_play_track_permission: can_play_track_permission,
      can_pause_track_permission: can_pause_track_permission,
      can_play_next_track_permission: can_play_next_track_permission,
      can_play_previous_track_permission: can_play_previous_track_permission,
    } = permissions_setup()
    # Creates permission group relationships
    permission_group_fixture(%{
      permission_id: can_add_room_collaborators_permission.id,
      group_id: room_admin_group.id
    })
    permission_group_fixture(%{
      permission_id: can_remove_room_collaborators_permission.id,
      group_id: room_admin_group.id
    })
    permission_group_fixture(%{
      permission_id: can_edit_room_management_type_permission.id,
      group_id: room_admin_group.id
    })
    permission_group_fixture(%{
      permission_id: can_edit_room_name_permission.id,
      group_id: room_admin_group.id
    })
    permission_group_fixture(%{
      permission_id: can_play_track_permission.id,
      group_id: room_admin_group.id
    })
    permission_group_fixture(%{
      permission_id: can_pause_track_permission.id,
      group_id: room_admin_group.id
    })
    permission_group_fixture(%{
      permission_id: can_play_next_track_permission.id,
      group_id: room_admin_group.id
    })
    permission_group_fixture(%{
      permission_id: can_play_previous_track_permission.id,
      group_id: room_admin_group.id
    })
    permission_group_fixture(%{
      permission_id: can_edit_room_management_type_permission.id,
      group_id: room_collaborator_group.id
    })
    permission_group_fixture(%{
      permission_id: can_edit_room_name_permission.id,
      group_id: room_collaborator_group.id
    })

    badges_setup()

    # Returns an Admin group that can be assigned to create room owners using
    # user_room fixtures
    %{group: room_admin_group}
  end

  def create_room_ownership(admin_group, room_attrs) do
    # Associates a group id to a new user for a new room and makes this user
    # an owner of the room
    %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
      is_owner: true, group_id: admin_group.id
    }, %{}, room_attrs)
    %{room: room, user: user}
  end
end
