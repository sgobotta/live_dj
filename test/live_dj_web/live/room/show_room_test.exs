defmodule LiveDjWeb.ShowRoomTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Repo
  import LiveDj.OrganizerFixtures
  import LiveDj.DataCase
  import Phoenix.LiveViewTest

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

  @tag wip: true
  describe "ShowLive chat behaviour" do

    @new_message_form_id "#new-message"
    @new_message_form_input_id "#new-message-input"

    setup(%{conn: conn}) do
      %{group: group} = show_live_setup()

      %{conn: conn, group: group |> Repo.preload([:permissions])}
    end

    test "As a Registered user I can communicate with other peers by typing a messag in the chat box",
      %{conn: conn, group: group}
    do
      # Associates a group id to a new user for a new room
      %{room: room, user: user, user_room: _user_room} = user_room_fixture(%{
        is_owner: false, group_id: group.id
      })
      # Creates a new authenticated connection
      owner_conn = log_in_user(conn, user)
      {:ok, view, _html} = live(owner_conn, "/room/#{room.slug}")
      # Simulates a chat interaction
      view
        |> element(@new_message_form_id)
        |> render_change(%{})
      view
        |> element(@new_message_form_input_id)
        |> render_blur(%{value: "Hi?"})
      view
        |> element(@new_message_form_id)
        |> render_submit(%{submit: %{message: "Hello!"}})
      # Establishes a connection
      %{assigns: %{user: user}} = get(owner_conn, "/room/#{room.slug}")

      refute render(view) =~ "Hi?"
      assert render(view) =~ "Hello!"
      assert render(view) =~ user.username
    end
  end
end
