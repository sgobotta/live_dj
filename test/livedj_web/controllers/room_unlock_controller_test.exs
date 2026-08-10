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
end
