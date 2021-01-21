defmodule LiveDjWeb.BadgesAssignmentsTest do
  use LiveDjWeb.ConnCase, async: true

  alias LiveDj.Organizer
  alias LiveDj.Stats

  import LiveDj.StatsFixtures
  import Phoenix.LiveViewTest

  @valid_room_attrs %{slug: "some slug", title: "some title"}
  @create_room_form_id "#create_room"

  describe "Room badges assignment" do

    setup(%{conn: conn}) do
      badges = badges_fixture()
      Map.merge(register_and_log_in_user(%{conn: conn}), %{badges: badges})
    end

    test "As a User When I create my first room A 'first room badge' is received", %{conn: conn, user: user, badges: badges} do
      {:ok, view, _html} = live(conn, "/")

      view
        |> element(@create_room_form_id)
        |> render_change(%{room: @valid_room_attrs})

      render_click(view, :save)

      badge = Enum.find(
        badges,
        fn badge -> badge.reference_name == "rooms-create_once" end
      )

      refute Stats.has_badge_by(user.id, badge.id)

    end
  end

end
