defmodule LiveDjWeb.ShowRoomTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Repo
  import LiveDj.OrganizerFixtures
  import LiveDj.DataCase

  describe "ShowLive user room groups assignation" do

    setup(%{conn: conn}) do
      %{group: group} = show_live_setup()

      %{conn: conn, group: group |> Repo.preload([:permissions])}
    end

    test "As a registered User When I belong to a group associated to a room I obtain those group permissions",
      %{conn: conn, group: group}
    do
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: false, group_id: group.id
      })
      conn = log_in_user(conn, user)

      %{assigns: assigns} = _conn = get(conn, "/room/#{room.slug}")

      refute assigns.visitor
      assert assigns.user_room_group.permissions == group.permissions
    end

    test "As a registered User When I don't belong to a group associated to a room I obtain no permissions",
      %{conn: conn}
    do
      %{conn: conn, user: _user} = register_and_log_in_user(%{conn: conn})
      room = room_fixture()
      %{assigns: assigns} = _conn = get(conn, "/room/#{room.slug}")

      refute assigns.visitor
      assert assigns.user_room_group.permissions == []
    end

    test "As a visitor User I obtain no permissions", %{conn: conn} do
      room = room_fixture()
      %{assigns: assigns} = _conn = get(conn, "/room/#{room.slug}")

      assert assigns.visitor
      assert assigns.user_room_group.permissions == []
    end
  end
end
