defmodule LivedjWeb.RoomUnlockController do
  use LivedjWeb, :controller

  alias Livedj.Sessions
  alias LivedjWeb.RoomAuth

  def new(conn, %{"room_id" => id}) do
    room = Sessions.get_room!(id)

    if Sessions.room_protected?(room) do
      render(conn, :new,
        room: room,
        error: nil,
        page_title: room.name,
        layout: false
      )
    else
      redirect(conn, to: ~p"/sessions/rooms/#{room}")
    end
  end

  def create(conn, %{"room_id" => id, "password" => password}) do
    room = Sessions.get_room!(id)

    if Sessions.verify_room_password(room, password) do
      authorized = get_session(conn, "authorized_rooms") || %{}

      conn
      |> put_session(
        "authorized_rooms",
        Map.put(authorized, room.id, Sessions.authorization_fingerprint(room))
      )
      |> redirect(to: ~p"/sessions/rooms/#{room}")
    else
      conn
      |> render(:new,
        room: room,
        error: gettext("Incorrect password. Please try again."),
        page_title: room.name,
        layout: false
      )
    end
  end

  def grant(conn, %{"room_id" => id, "token" => token}) do
    room = Sessions.get_room!(id)

    case RoomAuth.verify_grant(token) do
      {:ok, ^id} ->
        conn
        |> maybe_authorize(room)
        |> redirect(to: ~p"/sessions/rooms/#{room}/welcome")

      _invalid ->
        redirect(conn, to: ~p"/sessions/rooms/#{room}/unlock")
    end
  end

  defp maybe_authorize(conn, room) do
    if Sessions.room_protected?(room) do
      authorized = get_session(conn, "authorized_rooms") || %{}

      put_session(
        conn,
        "authorized_rooms",
        Map.put(authorized, room.id, Sessions.authorization_fingerprint(room))
      )
    else
      conn
    end
  end
end
