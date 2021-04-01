# defmodule LiveDjWeb.Live.Components.PeersTest do
#   use LiveDjWeb.ConnCase, async: true

#   import LiveDj.AccountsFixtures
#   import LiveDj.StatsFixtures
#   import Phoenix.LiveViewTest

#   describe "Peers test" do

#     alias LiveDj.OrganizerFixtures

#     setup(%{conn: conn}) do
#       badge = badge_fixture(%{checkpoint: 1, type: "queue-track-contribution"})
#       group = group_fixture(%{codename: "room-admin", name: "Room admin"})
#       group_fixture(%{codename: "anonymous-room-visitor", name: "Anonymous room visitor"})
#       group_fixture(%{codename: "registered-room-visitor", name: "Registered room visitor"})
#       %{
#         user_room: another_user_room_relationship,
#         user: another_user,
#         room: another_user_room
#       } = OrganizerFixtures.user_room_fixture(%{group_id: group.id})

#       Map.merge(
#         register_and_log_in_user(%{conn: conn}),
#         %{another_user: another_user, another_user_room: another_user_room, another_user_room_relationship: another_user_room_relationship, badge: badge}
#       )
#     end

#     test "todo",
#       %{another_user: _another_user, another_user_room: another_user_room, another_user_room_relationship: _another_user_room_relationship, conn: conn, badge: _badge, user: _user}
#     do
#       {:ok, _view, _html} = live(conn, "/room/#{another_user_room.slug}")

#     end
#   end
# end
