defmodule LiveDjWeb.Live.Room.NewRoomTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Organizer

  import LiveDj.AccountsFixtures
  import LiveDj.OrganizerFixtures
  import LiveDj.DataCase
  import Phoenix.LiveViewTest

  @valid_room_attrs %{slug: "some slug", title: "some title"}
  @create_room_form_id "#create_room"

  describe "room handlers" do

    setup(%{conn: conn}) do
      show_live_setup()

      # Creates some rooms
      rooms = rooms_fixture()

      %{conn: conn, rooms: rooms}
    end

    test "handle_info/2 :reload_room_list", %{conn: new_live_conn, rooms: rooms} do
      # Gets a random room
      room = Enum.at(rooms, Enum.random(0..length(rooms)-1))
      %{assigns: assigns} = new_live_conn = get(new_live_conn, "/")

      room_viewers = Enum.reduce(
        assigns.viewers_quantity, 0,
        fn {_, quantity}, acc -> quantity + acc end
      )
      assert room_viewers == 0

      # Creates a connection to the new live view page
      {:ok, new_live_view, _html} = live(new_live_conn, "/")
      send(new_live_view.pid, :reload_room_list)

      # Creates 3 connections
      _conns = create_connections("/room/#{room.slug}", 3)
      # for _ <- 0..2 do
      #   get(build_conn(), "/room/#{room.slug}")
      # end

      %{assigns: assigns} = _new_live_conn = get(new_live_conn, "/")
      room_viewers = Enum.reduce(
        assigns.viewers_quantity, 0,
        fn {_, quantity}, acc -> quantity + acc end
      )
      assert room_viewers == 3
    end

    test "handle_info/2 :receive_current_player", %{conn: new_live_conn, rooms: rooms} do
      initial_player_state = LiveDj.Organizer.Player.get_initial_state()
      {player_states, room_urls} = _rooms_data = Enum.reduce(rooms, {[], []},
        fn %{slug: slug, queue: queue}, {player_states, room_urls} ->
          %{video_id: video_id, previous: previous, next: next} = Enum.at(
            queue, Enum.random(0..length(queue)-1)
          )
          player_state = LiveDj.Organizer.Player.update(
            initial_player_state,
            %{state: "playing", video_id: video_id, previous_id: previous, next_id: next}
          )
          {player_states ++ [player_state], room_urls ++ ["/room/#{slug}"]}
        end
      )

      show_live_conns = create_live_connections(room_urls)

      {:ok, new_live_view, _html} = live(new_live_conn, "/")

      # FIXME: properly assign player states
      for {_conn, {:ok, view, _html}, _url} <- show_live_conns do
        send(view.pid, {:player_signal_playing, %{state: Enum.at(player_states, 0)}})
      end
      _show_live_conns = for {conn, {:ok, view, _html}, url} <- show_live_conns do
        conn = get(conn, url)
        send(view.pid, {:request_current_player, %{}})
        conn
      end

      send(new_live_view.pid, :tick)
      # Creates a connection to the new live view page
      %{assigns: %{public_rooms: public_rooms}} = _new_live_conn = get(new_live_conn, "/")

      assert length(public_rooms) == length(rooms)

      # FIXME: assert players, not rooms. Clean code up.
    end
  end

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
      rooms = for _n <- 0..2, do: OrganizerFixtures.room_fixture(%{queue: []})

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
      rooms = for _n <- 1..3, do: OrganizerFixtures.room_fixture(%{queue: []})
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
