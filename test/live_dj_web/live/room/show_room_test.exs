defmodule LiveDjWeb.ShowRoomTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Repo

  import LiveDj.AccountsFixtures
  import LiveDj.OrganizerFixtures

  describe "ShowLive user room groups Assignation" do

    setup(%{conn: conn}) do
      # Creates an initial group
      group = group_fixture()
      # Just creates 3 permissions and associates them to a group
      permissions = for _n <- 1..3, do: permission_fixture()
      {:ok, _permission_group} = permissions_group_fixture(%{
        permissions: permissions,
        group_id: group.id
      })
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: false, group_id: group.id
      })

      conn = log_in_user(conn, user)

      %{conn: conn, group: group |> Repo.preload([:permissions]), room: room}
    end

    test "As a registered User When I belong to a certain group associated to a room I obtain those group permissions",
      %{conn: conn, group: group, room: room}
    do
      %{assigns: assigns} = _conn = get(conn, "/room/#{room.slug}")

      assert group.permissions == assigns.user_room_group.permissions
    end
  end
end
