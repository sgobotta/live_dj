defmodule LiveDjWeb.BadgesAssignmentsTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Stats

  import LiveDj.AccountsFixtures
  import LiveDj.StatsFixtures
  import Phoenix.LiveViewTest

  @valid_room_attrs %{slug: "some slug", title: "some title"}
  @create_room_form_id "#create_room"

  describe "Room badges assignment" do
    setup(%{conn: conn}) do
      badge = badge_fixture(%{checkpoint: 1, type: "rooms-creation"})
      _group = group_fixture(%{codename: "room-admin", name: "Room admin"})
      Map.merge(register_and_log_in_user(%{conn: conn}), %{badge: badge})
    end

    test "As a User When I create my first room A 'First Room' badge is received",
         %{
           conn: conn,
           user: user,
           badge: badge
         } do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element(@create_room_form_id)
      |> render_change(%{room: @valid_room_attrs})

      render_click(view, :save)

      assert Stats.has_badge_by(user.id, badge.id)
    end
  end
end
