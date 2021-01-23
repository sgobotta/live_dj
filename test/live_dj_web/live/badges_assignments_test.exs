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

    test "As a User When I create my first room A 'First Room' badge is received", %{conn: conn, user: user, badge: badge} do
      {:ok, view, _html} = live(conn, "/")

      view
        |> element(@create_room_form_id)
        |> render_change(%{room: @valid_room_attrs})

      render_click(view, :save)

      assert Stats.has_badge_by(user.id, badge.id)
    end
  end

  describe "Queue track badges assignment" do

    alias LiveDj.OrganizerFixtures

    # @search_video_form_id "#search-video-form"

    setup(%{conn: conn}) do
      badge = badge_fixture(%{checkpoint: 1, type: "queue-track-contribution"})
      group = group_fixture(%{codename: "room-admin", name: "Room admin"})
      %{
        user_room: another_user_room_relationship,
        user: another_user,
        room: another_user_room
      } = OrganizerFixtures.user_room_fixture(%{group_id: group.id})

      Map.merge(
        register_and_log_in_user(%{conn: conn}),
        %{another_user: another_user, another_user_room: another_user_room, another_user_room_relationship: another_user_room_relationship, badge: badge}
      )
    end

    test "As a User When I add a track to another user's room queue A 'Cooperative Dj' badge is received",
      %{another_user: _another_user, another_user_room: another_user_room, another_user_room_relationship: _another_user_room_relationship, conn: conn, badge: _badge, user: _user}
    do
      {:ok, _view, _html} = live(conn, "/room/#{another_user_room.slug}")

      # view
      #   |> element(@search_video_form_id)
      #   |> render_change(%{search_field: @valid_search_video_attrs})

      #   rendered_view = render_click(view, :save)

    end
  end
end
