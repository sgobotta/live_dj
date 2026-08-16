defmodule LivedjWeb.Sessions.RoomLive.IndexTest do
  @moduledoc false
  use LivedjWeb.ConnCase

  import Phoenix.LiveViewTest
  import Livedj.SessionsFixtures

  setup :register_and_log_in_user

  test "creates a protected room when a password is provided", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sessions/rooms/new")

    view
    |> form("#room-form", room: %{name: "Locked Room", password: "secret1"})
    |> render_submit()

    room = Enum.find(Livedj.Sessions.list_rooms(), &(&1.name == "Locked Room"))
    assert Livedj.Sessions.room_protected?(room)
  end

  test "creates a public room when no password is provided", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sessions/rooms/new")

    view
    |> form("#room-form", room: %{name: "Open Room", password: ""})
    |> render_submit()

    room = Enum.find(Livedj.Sessions.list_rooms(), &(&1.name == "Open Room"))
    refute Livedj.Sessions.room_protected?(room)
  end

  test "shows a lock badge only on protected rooms", %{conn: conn} do
    _public = room_fixture(%{name: "Public Room"})
    _locked = room_fixture(%{name: "Locked Room", password: "secret1"})

    {:ok, _view, html} = live(conn, ~p"/sessions/rooms")

    assert html =~ "room-lock-badge"
    # exactly one badge (only the protected room)
    assert length(String.split(html, "class=\"room-lock-badge")) == 2
  end

  test "renders the lock badge inside the album cover container", %{conn: conn} do
    _locked = room_fixture(%{name: "Locked Room", password: "secret1"})

    {:ok, _view, html} = live(conn, ~p"/sessions/rooms")

    badges =
      html
      |> Floki.parse_document!()
      |> Floki.find(".song-cover-container .room-lock-badge")

    assert length(badges) == 1
  end

  test "renders an empty state when there are no rooms", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/sessions/rooms")

    # "No rooms yet" renders as "No hay salas" under the default "es" locale.
    assert html =~ "No hay salas"
    # No featured hero and no grid when there are no rooms.
    refute html =~ ~s(id="room-grid")
  end

  test "features one room and lists the rest in a grid", %{conn: conn} do
    _first = room_fixture(%{name: "First Room"})
    _second = room_fixture(%{name: "Second Room"})

    {:ok, _view, html} = live(conn, ~p"/sessions/rooms")

    # One room is featured (hero), the rest render in the grid.
    assert html =~ "Featured"
    assert html =~ ~s(id="room-grid")
    assert html =~ "First Room"
    assert html =~ "Second Room"
    refute html =~ "No rooms yet"
  end

  test "reorders 'more rooms' by live user count in real time", %{conn: conn} do
    featured = room_fixture(%{name: "Featured Room"})
    _quiet = room_fixture(%{name: "Quiet Room"})
    busy = room_fixture(%{name: "Busy Room"})

    # Keep "Featured Room" the hero throughout the test by giving it more
    # concurrent users than "Busy Room" will ever have, so only the "More
    # rooms" grid order is under test.
    start_tracked_user(featured.id)
    start_tracked_user(featured.id)
    Process.sleep(50)

    {:ok, view, html} = live(conn, ~p"/sessions/rooms")

    assert grid_room_order(html) == ["Quiet Room", "Busy Room"]

    tracker = start_tracked_user(busy.id)

    # Wait for the tracker to register, then let the LiveView flush the
    # `presence_diff` broadcast it's already subscribed to.
    Process.sleep(50)
    html = render(view)

    assert grid_room_order(html) == ["Busy Room", "Quiet Room"]

    Process.exit(tracker, :kill)
    Process.sleep(50)
    html = render(view)

    assert grid_room_order(html) == ["Quiet Room", "Busy Room"]
  end

  # Presence tracking has to happen from a process that stays alive for as
  # long as the user is "present". Fixture creation needs the test's Ecto
  # sandbox connection, so the user is built here and only tracking happens
  # in the (deliberately unlinked, so we can kill it mid-test) spawned
  # process.
  defp start_tracked_user(room_id) do
    user = Livedj.AccountsFixtures.user_fixture()

    pid =
      spawn(fn ->
        Livedj.Presence.track_user(room_id, user)
        Process.sleep(:infinity)
      end)

    on_exit(fn -> Process.exit(pid, :kill) end)

    pid
  end

  defp grid_room_order(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("#room-grid p.font-medium")
    |> Enum.map(&String.trim(Floki.text(&1)))
  end

  test "creating a protected room navigates through the unlock grant", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/sessions/rooms/new")

    render_submit(
      form(view, "#room-form", room: %{name: "Locked", password: "secret1"})
    )

    assert {to, _flash} = assert_redirect(view)
    assert to =~ "/unlock/grant?"
  end
end
