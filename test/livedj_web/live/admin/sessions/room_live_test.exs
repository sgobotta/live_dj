defmodule LivedjWeb.Admin.Sessions.RoomLiveTest do
  use LivedjWeb.ConnCase

  import Phoenix.LiveViewTest
  import Livedj.SessionsFixtures

  @create_attrs %{name: "some name", slug: "some slug"}
  @update_attrs %{name: "some updated name", slug: "some updated slug"}
  @invalid_attrs %{name: nil, slug: nil}

  defp create_room(_context) do
    room = room_fixture()
    %{room: room}
  end

  describe "Index" do
    setup [:create_room]

    test "lists all rooms", %{conn: conn, room: room} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/sessions/rooms")

      assert html =~ "Listing Rooms"
      assert html =~ room.name
    end

    test "saves new room", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/sessions/rooms")

      assert index_live |> element("a", "New Room") |> render_click() =~
               "New Room"

      assert_patch(index_live, ~p"/admin/sessions/rooms/new")

      assert index_live
             |> form("#room-form", room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#room-form", room: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/sessions/rooms")

      html = render(index_live)
      assert html =~ "Room created successfully"
      assert html =~ "some name"
    end

    test "updates room in listing", %{conn: conn, room: room} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/sessions/rooms")

      assert index_live
             |> element("#rooms-#{room.id} a", "Edit")
             |> render_click() =~
               "Edit Room"

      assert_patch(index_live, ~p"/admin/sessions/rooms/#{room}/edit")

      assert index_live
             |> form("#room-form", room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#room-form", room: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/sessions/rooms")

      html = render(index_live)
      assert html =~ "Room updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes room in listing", %{conn: conn, room: room} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/sessions/rooms")

      assert index_live
             |> element("#rooms-#{room.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#rooms-#{room.id}")
    end
  end

  describe "Show" do
    setup [:create_room]

    test "displays room", %{conn: conn, room: room} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/sessions/rooms/#{room}")

      assert html =~ "Show Room"
      assert html =~ room.name
    end

    test "updates room within modal", %{conn: conn, room: room} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/sessions/rooms/#{room}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Room"

      assert_patch(show_live, ~p"/admin/sessions/rooms/#{room}/show/edit")

      assert show_live
             |> form("#room-form", room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#room-form", room: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/sessions/rooms/#{room}")

      html = render(show_live)
      assert html =~ "Room updated successfully"
      assert html =~ "some updated name"
    end
  end
end
