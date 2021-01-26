defmodule LiveDjWeb.Live.Room.NewRoomTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Organizer

  import LiveDj.AccountsFixtures
  import Phoenix.LiveViewTest

  @valid_room_attrs %{slug: "some slug", title: "some title"}
  @create_room_form_id "#create_room"

  describe "As a visitor user When I visit /" do
    test "the NewLive module is rendered", %{conn: conn} do
      conn = get(conn, "/")
      assert conn.status == 200

      {:ok, view, _html} = live(conn, "/")
      assert view.module == LiveDjWeb.Room.NewLive
    end
    # Implement navbar tests
  end

  describe "As a visitor user When there are no rooms" do
    test "An empty list is rendered", %{conn: conn} do
      %{assigns: assigns} = conn = get(conn, "/")

      %{public_rooms: public_rooms} = assigns
      assert public_rooms == []

      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Go ahead, create the first room!"
    end
  end

  describe "As a registered user When there are no rooms" do
    setup(%{conn: conn}) do
      register_and_log_in_user(%{conn: conn})
    end

    test "An empty list is rendered", %{conn: conn} do
      %{assigns: assigns} = conn = get(conn, "/")

      %{public_rooms: public_rooms} = assigns
      assert public_rooms == []

      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Go ahead, create the first room!"
    end
  end

  describe "As a visitor user When there are rooms" do

    alias LiveDj.OrganizerFixtures

    setup do
      rooms = for _n <- 1..3, do: OrganizerFixtures.room_fixture()

      %{rooms: rooms}
    end

    test "The rooms assigns contain a public rooms list", %{conn: conn, rooms: rooms} do
      %{assigns: assigns} = _conn = get(conn, "/")
      %{public_rooms: public_rooms} = assigns

      assert public_rooms == rooms
    end
  end

  describe "As a registered user When there are rooms" do

    alias LiveDj.OrganizerFixtures

    setup(%{conn: conn}) do
      rooms = for _n <- 1..3, do: OrganizerFixtures.room_fixture()
      Map.merge(register_and_log_in_user(%{conn: conn}), %{rooms: rooms})
    end

    test "The rooms assigns contain a public rooms list", %{conn: conn, rooms: rooms} do
      %{assigns: assigns} = _conn = get(conn, "/")

      %{public_rooms: public_rooms} = assigns
      assert public_rooms == rooms
    end
  end

  describe "As a visitor user When I want to create a room" do

    test "An error alert is returned if the title input is empty", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
        |> element(@create_room_form_id)
        |> render_change(%{room: %{slug: "A slug"}})

      assert render_click(view, :save) =~ "can&apos;t be blank"
    end

    test "An error alert is returned if the slug input is empty", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
        |> element(@create_room_form_id)
        |> render_change(%{room: %{title: "A title"}})

      assert render_click(view, :save) =~ "can&apos;t be blank"
    end

    test "A redirection is performed if the room is created", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      expected_redirection_path_value = "/room/some-slug"

      view
        |> element(@create_room_form_id)
        |> render_change(%{room: @valid_room_attrs})

      assert {:error, {:redirect, %{to: ^expected_redirection_path_value}}} = render_click(view, :save)
      assert_redirected view, expected_redirection_path_value
    end

    test "An error alert is returned if I choose managed as the management_type option", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      management = %{management_type: "managed"}
      view
        |> element(@create_room_form_id)
        |> render_change(%{room: Enum.into(management, @valid_room_attrs)})

        assert render_click(view, :save) =~ "Please sign in with a username to create managed rooms."
    end
  end

  describe "As a registered user When I want to create a room" do

    setup(%{conn: conn}) do
      register_and_log_in_user(%{conn: conn})
    end

    test "An error alert is returned if the title input is empty", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user)
      {:ok, view, _html} = live(conn, "/")

      view
        |> element(@create_room_form_id)
        |> render_change(%{room: %{slug: "A slug"}})

      assert render_click(view, :save) =~ "can&apos;t be blank"
    end

    test "An error alert is returned if the slug input is empty", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user)
      {:ok, view, _html} = live(conn, "/")

      view
        |> element(@create_room_form_id)
        |> render_change(%{room: %{title: "A title"}})

      assert render_click(view, :save) =~ "can&apos;t be blank"
    end

    test "with a managed management_type value, A redirection is performed and a user/room relationship is created",
      %{conn: conn, user: user}
    do
      group_fixture(%{codename: "room-admin", name: "Room admin"})
      conn = conn |> log_in_user(user)
      {:ok, view, _html} = live(conn, "/")

      expected_redirection_path_value = "/room/some-slug"

      management = %{management_type: "managed"}
      view
        |> element(@create_room_form_id)
        |> render_change(%{room: Enum.into(management, @valid_room_attrs)})

      rendered_view = render_click(view, :save)
      assert {:error, {:redirect, %{to: ^expected_redirection_path_value}}} = rendered_view

      {:ok, conn} = rendered_view |> follow_redirect(conn)
      %{assigns: %{room: room}} = conn

      assert_redirected(view, expected_redirection_path_value)
      # When a room is created, the user that triggers the action is the owner
      # by default.
      assert Organizer.has_user_room_by(user.id, room.id, true)
      assert room.management_type == "managed"
    end

    test "A redirection is performed and a user/room relationship is created", %{conn: conn, user: user} do
      group_fixture(%{codename: "room-admin", name: "Room admin"})
      conn = conn |> log_in_user(user)
      {:ok, view, _html} = live(conn, "/")

      expected_redirection_path_value = "/room/some-slug"

      view
        |> element(@create_room_form_id)
        |> render_change(%{room: @valid_room_attrs})

      rendered_view = render_click(view, :save)
      assert {:error, {:redirect, %{to: ^expected_redirection_path_value}}} = rendered_view

      {:ok, conn} = rendered_view |> follow_redirect(conn)
      %{assigns: %{room: room}} = conn

      assert_redirected(view, expected_redirection_path_value)
      # When a room is created, the user that triggers the action is the owner
      # by default.
      assert Organizer.has_user_room_by(user.id, room.id, true)
      assert room.management_type == "free"
    end
  end
end
