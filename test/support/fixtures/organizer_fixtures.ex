defmodule LiveDj.OrganizerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Organizer` context.
  """

  alias LiveDj.AccountsFixtures

  @room_queue [%{
    next: "Wch3gJG2GJ4",
    title: "2 Second Video",
    img_url: "https://i.ytimg.com/vi/TK4N5W22Gts/default.jpg",
    added_by: %{
      uuid: "05ffb9af-ea4b-485f-9860-3264c3cdf404",
      username: "sann"
    },
    previous: "UO_QuXr521I",
    video_id: "TK4N5W22Gts",
    img_width: 120,
    is_queued: false,
    img_height: 90,
    description: "2 Second Video Sequal To 1 Second Video.",
    channel_title: "Zetzu500"
  },
  %{
    next: "tbnLqRW9Ef0",
    title: "1 Second Video",
    img_url: "https://i.ytimg.com/vi/Wch3gJG2GJ4/default.jpg",
    added_by: %{
      uuid: "05ffb9af-ea4b-485f-9860-3264c3cdf404",
      username: "sann"
    },
    previous: "TK4N5W22Gts",
    video_id: "Wch3gJG2GJ4",
    img_width: 120,
    is_queued: false,
    img_height: 90,
    description: "1 Second Video IT SUCKS!",
    channel_title: "Zetzu500"
  }]

  def rooms_fixture do
    for _n <- 0..3 do
      room_fixture(%{queue: @room_queue})
    end
  end

  def room_fixture(attrs \\ %{}) do
    random_words = Enum.join(Faker.Lorem.words(5), " ")
    {:ok, room} =
      attrs
      |> Enum.into(%{
        title: random_words,
        slug: random_words,
        queue: @room_queue
      })
      |> LiveDj.Organizer.create_room()
      room
  end

  def user_room_fixture(
    attrs \\ %{}, user_attrs \\ %{}, room_attrs \\ %{}, group_attrs \\ %{}
  ) do
    user = AccountsFixtures.user_fixture(user_attrs)
    room = room_fixture(room_attrs)
    group = AccountsFixtures.group_fixture(group_attrs)
    {:ok, user_room} =
      attrs
      |> Enum.into(%{is_owner: true, room_id: room.id, user_id: user.id, group_id: group.id})
      |> LiveDj.Organizer.create_user_room()
    %{room: room, user: user, user_room: user_room}
  end
end
