defmodule LivedjWeb.Sessions.RoomLive.ShowTest do
  @moduledoc false
  use LivedjWeb.ConnCase

  import Phoenix.LiveViewTest
  import Livedj.SessionsFixtures

  setup [:register_and_log_in_user, :create_room]

  defp create_room(_context) do
    %{room: room_fixture()}
  end

  describe "display name on first (disconnected) render" do
    test "uses the name stored in the per-room cookie", %{
      conn: conn,
      room: room
    } do
      conn =
        conn
        |> put_req_cookie("livedj_display_name_#{room.id}", "CustomName")
        |> get(~p"/sessions/rooms/#{room}")

      # The chosen name must already be present in the very first HTML the
      # server returns, so there is no default-name flash before connect.
      assert html_response(conn, 200) =~ "CustomName"
    end

    test "a cookie for a different room is ignored", %{conn: conn, room: room} do
      conn =
        conn
        |> put_req_cookie("livedj_display_name_some-other-room", "OtherRoom")
        |> get(~p"/sessions/rooms/#{room}")

      refute html_response(conn, 200) =~ "OtherRoom"
    end
  end

  describe "password gate" do
    test "redirects an unauthorized visitor of a protected room to /unlock", %{
      conn: conn
    } do
      room = room_fixture(%{password: "secret1"})

      assert {:error, {:redirect, %{to: to}}} =
               live(conn, ~p"/sessions/rooms/#{room}")

      assert to == ~p"/sessions/rooms/#{room}/unlock"
    end

    test "allows a visitor whose session holds a matching fingerprint", %{
      conn: conn
    } do
      room = room_fixture(%{password: "secret1"})
      fingerprint = Livedj.Sessions.authorization_fingerprint(room)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session("authorized_rooms", %{room.id => fingerprint})

      assert {:ok, _view, _html} = live(conn, ~p"/sessions/rooms/#{room}")
    end

    test "allows any visitor of a public room", %{conn: conn, room: room} do
      assert {:ok, _view, _html} = live(conn, ~p"/sessions/rooms/#{room}")
    end
  end

  describe "edit password modal" do
    test "sets a password from the settings modal", %{conn: conn, room: room} do
      {:ok, view, _html} =
        live(conn, ~p"/sessions/rooms/#{room}/settings/security")

      view
      |> form("#room-password-form", %{password: "secret1"})
      |> render_submit()

      assert Livedj.Sessions.room_protected?(Livedj.Sessions.get_room!(room.id))
    end

    test "shows the changeset error when the password is too long", %{
      conn: conn,
      room: room
    } do
      {:ok, view, _html} =
        live(conn, ~p"/sessions/rooms/#{room}/settings/security")

      html =
        view
        |> form("#room-password-form", %{password: String.duplicate("a", 33)})
        |> render_submit()

      # message reflects the max constraint, not the hardcoded min
      assert html =~ "como máximo 32"
      refute html =~ "al menos 4 caracteres"
    end

    test "removes an existing password", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})
      fingerprint = Livedj.Sessions.authorization_fingerprint(room)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session("authorized_rooms", %{room.id => fingerprint})

      {:ok, view, _html} =
        live(conn, ~p"/sessions/rooms/#{room}/settings/security")

      view |> element("#remove-room-password") |> render_click()

      refute Livedj.Sessions.room_protected?(Livedj.Sessions.get_room!(room.id))
    end
  end

  describe "edit general modal" do
    test "renames the room from the settings modal", %{conn: conn, room: room} do
      {:ok, view, _html} =
        live(conn, ~p"/sessions/rooms/#{room}/settings/general")

      view
      |> form("#room-name-form", %{name: "New Room Name"})
      |> render_submit()

      assert Livedj.Sessions.get_room!(room.id).name == "New Room Name"
    end

    test "shows the changeset error for a blank name", %{
      conn: conn,
      room: room
    } do
      {:ok, view, _html} =
        live(conn, ~p"/sessions/rooms/#{room}/settings/general")

      html =
        view
        |> form("#room-name-form", %{name: ""})
        |> render_submit()

      assert html =~ "no puede estar en blanco"
      assert Livedj.Sessions.get_room!(room.id).name == room.name
    end
  end

  describe "refreshing in-room visitors on a password change" do
    setup %{conn: conn} do
      room = room_fixture(%{password: "secret1"})
      fingerprint = Livedj.Sessions.authorization_fingerprint(room)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session("authorized_rooms", %{room.id => fingerprint})

      %{conn: conn, room: room}
    end

    test "pushes a grant refresh when the password changes", %{
      conn: conn,
      room: room
    } do
      {:ok, view, _html} = live(conn, ~p"/sessions/rooms/#{room}")

      {:ok, _room} =
        Livedj.Sessions.update_room_password(room, %{"password" => "secret2"})

      assert_push_event(view, "refresh_room_grant", %{url: url})
      assert url =~ "/sessions/rooms/#{room.id}/unlock/grant"
    end

    test "does not push a grant refresh when the password is removed", %{
      conn: conn,
      room: room
    } do
      {:ok, view, _html} = live(conn, ~p"/sessions/rooms/#{room}")

      {:ok, _room} =
        Livedj.Sessions.update_room_password(room, %{"password" => ""})

      refute_push_event(view, "refresh_room_grant", %{})
    end
  end

  describe "chat :announcement messages" do
    test "renders the actor name with no stray whitespace inside the underline",
         %{conn: conn, room: room} do
      {:ok, view, _html} = live(conn, ~p"/sessions/rooms/#{room}")
      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room.id}")

      :ok =
        Livedj.Sessions.chat_send_message(
          room.id,
          Ecto.UUID.generate(),
          "Alice",
          :announcement,
          "queued Some Song"
        )

      assert_receive {:message_sent, _room_id, _message}

      html = render(view)

      assert html =~
               ~s(<span class="font-semibold underline">Alice</span> queued Some Song)
    end

    test "using /name does not crash the LiveView", %{conn: conn, room: room} do
      {:ok, view, _html} = live(conn, ~p"/sessions/rooms/#{room}")

      view
      |> form("#chat-input-bar form", %{content: "/name Bob"})
      |> render_submit()

      assert Process.alive?(view.pid)
      assert render(view) =~ "Bob"
    end
  end

  describe "header settings icon" do
    test "opens the settings modal on the General tab", %{
      conn: conn,
      room: room
    } do
      {:ok, view, _html} = live(conn, ~p"/sessions/rooms/#{room}")

      view |> element("#settings-btn") |> render_click()

      assert_patch(view, ~p"/sessions/rooms/#{room}/settings/general")
      assert render(view) =~ "room-name-form"
    end
  end

  describe "security tab icon" do
    test "shows an open lock for a public room", %{conn: conn, room: room} do
      {:ok, view, _html} =
        live(conn, ~p"/sessions/rooms/#{room}/settings/security")

      assert render(view) =~ "hero-lock-open"
    end

    test "shows a closed lock for a protected room", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})
      fingerprint = Livedj.Sessions.authorization_fingerprint(room)

      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> Plug.Conn.put_session("authorized_rooms", %{room.id => fingerprint})

      {:ok, view, _html} =
        live(conn, ~p"/sessions/rooms/#{room}/settings/security")

      assert render(view) =~ "hero-lock-closed"
    end
  end
end
