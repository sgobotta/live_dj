defmodule LivedjWeb.RoomUnlockControllerTest do
  use LivedjWeb.ConnCase, async: true

  import Livedj.SessionsFixtures

  describe "GET /sessions/rooms/:room_id/unlock" do
    test "renders the challenge for a protected room", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})
      conn = get(conn, ~p"/sessions/rooms/#{room}/unlock")
      response = html_response(conn, 200)
      assert response =~ room.name
      assert response =~ "password"
    end

    test "redirects to the room for a public room", %{conn: conn} do
      room = room_fixture()
      conn = get(conn, ~p"/sessions/rooms/#{room}/unlock")
      assert redirected_to(conn) == ~p"/sessions/rooms/#{room}"
    end
  end

  describe "POST /sessions/rooms/:room_id/unlock" do
    test "authorizes and redirects on correct password", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})

      conn =
        post(conn, ~p"/sessions/rooms/#{room}/unlock", %{
          "password" => "secret1"
        })

      assert redirected_to(conn) == ~p"/sessions/rooms/#{room}"

      assert get_session(conn, "authorized_rooms") ==
               %{room.id => Livedj.Sessions.authorization_fingerprint(room)}
    end

    test "re-renders with an error on wrong password", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})

      conn =
        post(conn, ~p"/sessions/rooms/#{room}/unlock", %{"password" => "nope"})

      assert html_response(conn, 200) =~ room.name
      refute get_session(conn, "authorized_rooms")
    end
  end

  describe "invalid room ids" do
    test "returns 404 for a nonexistent (valid) room id", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, ~p"/sessions/rooms/#{Ecto.UUID.generate()}/unlock")
      end
    end

    test "returns 404 for a malformed room id", %{conn: conn} do
      assert_error_sent 404, fn ->
        get(conn, "/sessions/rooms/not-a-uuid/unlock")
      end
    end
  end

  describe "GET /sessions/rooms/:room_id/unlock/grant" do
    test "authorizes the creator with a valid token and redirects to welcome",
         %{
           conn: conn
         } do
      room = room_fixture(%{password: "secret1"})
      token = LivedjWeb.RoomAuth.sign_grant(room.id)

      conn =
        get(conn, ~p"/sessions/rooms/#{room}/unlock/grant?#{[token: token]}")

      assert redirected_to(conn) == ~p"/sessions/rooms/#{room}/welcome"

      assert get_session(conn, "authorized_rooms") ==
               %{room.id => Livedj.Sessions.authorization_fingerprint(room)}
    end

    test "silent grant authorizes and returns 204 without redirecting", %{
      conn: conn
    } do
      room = room_fixture(%{password: "secret1"})
      token = LivedjWeb.RoomAuth.sign_grant(room.id)

      conn =
        get(
          conn,
          ~p"/sessions/rooms/#{room}/unlock/grant?#{[token: token, silent: true]}"
        )

      assert conn.status == 204

      assert get_session(conn, "authorized_rooms") ==
               %{room.id => Livedj.Sessions.authorization_fingerprint(room)}
    end

    test "silent grant returns 403 when the token is invalid", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})

      conn =
        get(
          conn,
          ~p"/sessions/rooms/#{room}/unlock/grant?#{[token: "bogus", silent: true]}"
        )

      assert conn.status == 403
      refute get_session(conn, "authorized_rooms")
    end

    test "redirects to unlock when the token is invalid", %{conn: conn} do
      room = room_fixture(%{password: "secret1"})

      conn =
        get(conn, ~p"/sessions/rooms/#{room}/unlock/grant?#{[token: "bogus"]}")

      assert redirected_to(conn) == ~p"/sessions/rooms/#{room}/unlock"
      refute get_session(conn, "authorized_rooms")
    end

    test "a public room grant just redirects to welcome without authorizing", %{
      conn: conn
    } do
      room = room_fixture()
      token = LivedjWeb.RoomAuth.sign_grant(room.id)

      conn =
        get(conn, ~p"/sessions/rooms/#{room}/unlock/grant?#{[token: token]}")

      assert redirected_to(conn) == ~p"/sessions/rooms/#{room}/welcome"
      refute get_session(conn, "authorized_rooms")
    end
  end
end
