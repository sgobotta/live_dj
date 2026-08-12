defmodule LivedjWeb.RoomAuth do
  @moduledoc """
  LiveView `on_mount` guard enforcing room password protection. Unauthorized
  visitors of a protected room are redirected to the password challenge screen.
  """
  use LivedjWeb, :verified_routes

  import Phoenix.LiveView, only: [redirect: 2]

  alias Livedj.Sessions
  alias Livedj.Sessions.Exceptions.SessionRoomError
  alias Livedj.Sessions.Room

  @grant_salt "room authorization grant"
  @grant_max_age 60

  @doc "Signs a short-lived token proving the bearer may be authorized for the room."
  def sign_grant(room_id) do
    Phoenix.Token.sign(LivedjWeb.Endpoint, @grant_salt, room_id)
  end

  @doc "Verifies a grant token, returning {:ok, room_id} or an error tuple."
  def verify_grant(token) do
    Phoenix.Token.verify(LivedjWeb.Endpoint, @grant_salt, token,
      max_age: @grant_max_age
    )
  end

  def on_mount(:ensure_room_access, %{"id" => id}, session, socket) do
    room = Sessions.get_room!(id)

    if authorized?(room, session) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/sessions/rooms/#{room}/unlock")}
    end
  rescue
    SessionRoomError ->
      {:halt, redirect(socket, to: ~p"/")}
  end

  defp authorized?(%Room{password_hash: nil}, _session), do: true

  defp authorized?(%Room{} = room, session) do
    authorized = Map.get(session, "authorized_rooms", %{})
    Map.get(authorized, room.id) == Sessions.authorization_fingerprint(room)
  end
end
