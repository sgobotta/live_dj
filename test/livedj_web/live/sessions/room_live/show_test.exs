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
end
