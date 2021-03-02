defmodule LiveDj.OrganizerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Organizer` context.
  """

  alias LiveDj.AccountsFixtures

  @room_queue [
    %{
      next: "dyp2mLYhRkw",
      title: "Video Countdown 3 seconds",
      img_url: "https://i.ytimg.com/vi/wUF9DeWJ0Dk/default.jpg",
      added_by: %{
        uuid: "071db349-de96-49dd-b084-00134aeca2d1",
        username: "guest-576460752303413630"
      },
      previous: "",
      video_id: "wUF9DeWJ0Dk",
      img_width: 120,
      is_queued: false,
      img_height: 90,
      description: "my cat is epic.",
      channel_title: "bvbb"
    },
    %{
      next: "FJ5pRIZXVks",
      title: "Video Countdown 20 Old  3 seconds",
      img_url: "https://i.ytimg.com/vi/dyp2mLYhRkw/default.jpg",
      added_by: %{
        uuid: "9dc9c9be-5c71-4b9d-88b8-0ca362d0f28c",
        username: "sann"
      },
      previous: "wUF9DeWJ0Dk",
      video_id: "dyp2mLYhRkw",
      img_width: 120,
      is_queued: false,
      img_height: 90,
      description: "",
      channel_title: "Bảo Anh"
    },
    %{
      next: "qu_uJQQo_Us",
      title: "#1 Countdown | 3 seconds with sound effect",
      img_url: "https://i.ytimg.com/vi/FJ5pRIZXVks/default.jpg",
      added_by: %{
        uuid: "9dc9c9be-5c71-4b9d-88b8-0ca362d0f28c",
        username: "sann"
      },
      previous: "dyp2mLYhRkw",
      video_id: "FJ5pRIZXVks",
      img_width: 120,
      is_queued: false,
      img_height: 90,
      description: "If you read this far down the description I love you. Please Hit that ▷ SUBSCRIBE button and LIKE my video and also turn ON notifications BELL! FOLLOW ...",
      channel_title: "DiaryBela"
    },
    %{
      next: "",
      title: "3 second video",
      img_url: "https://i.ytimg.com/vi/qu_uJQQo_Us/default.jpg",
      added_by: %{
        uuid: "05ffb9af-ea4b-485f-9860-3264c3cdf404",
        username: "wasabi"
      },
      previous: "FJ5pRIZXVks",
      video_id: "qu_uJQQo_Us",
      img_width: 120,
      is_queued: false,
      img_height: 90,
      description: "I created this video with the YouTube Slideshow Creator (http://www.youtube.com/upload)",
      channel_title: "Adam Bub"
    }
  ]

  def room_queue, do: @room_queue

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
