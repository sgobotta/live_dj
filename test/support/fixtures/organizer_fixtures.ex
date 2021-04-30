defmodule LiveDj.OrganizerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Organizer` context.
  """

  alias LiveDj.AccountsFixtures
  alias LiveDj.Collections
  alias LiveDj.CollectionsFixtures

  @room_queue [
    %{
      added_by: %{
        uuid: "071db349-de96-49dd-b084-00134aeca2d1",
        user_id: nil,
        username: "guest-576460752303413630"
      },
      channel_title: "bvbb",
      description: "my cat is epic.",
      img_height: 90,
      img_url: "https://i.ytimg.com/vi/wUF9DeWJ0Dk/default.jpg",
      img_width: 120,
      is_queued: false,
      next: "dyp2mLYhRkw",
      previous: "",
      video_id: "wUF9DeWJ0Dk",
      title: "Video Countdown 3 seconds"
    },
    %{
      added_by: %{
        uuid: "9dc9c9be-5c71-4b9d-88b8-0ca362d0f28c",
        user_id: nil,
        username: "sann"
      },
      channel_title: "Bảo Anh",
      description: "",
      img_height: 90,
      img_url: "https://i.ytimg.com/vi/dyp2mLYhRkw/default.jpg",
      img_width: 120,
      is_queued: false,
      next: "FJ5pRIZXVks",
      previous: "wUF9DeWJ0Dk",
      video_id: "dyp2mLYhRkw",
      title: "Video Countdown 20 Old  3 seconds"
    },
    %{
      added_by: %{
        uuid: "9dc9c9be-5c71-4b9d-88b8-0ca362d0f28c",
        user_id: nil,
        username: "sann"
      },
      channel_title: "DiaryBela",
      description:
        "If you read this far down the description I love you. Please Hit that ▷ SUBSCRIBE button and LIKE my video and also turn ON notifications BELL! FOLLOW ...",
      img_url: "https://i.ytimg.com/vi/FJ5pRIZXVks/default.jpg",
      img_height: 90,
      img_width: 120,
      is_queued: false,
      next: "qu_uJQQo_Us",
      previous: "dyp2mLYhRkw",
      video_id: "FJ5pRIZXVks",
      title: "#1 Countdown | 3 seconds with sound effect"
    },
    %{
      added_by: %{
        uuid: "05ffb9af-ea4b-485f-9860-3264c3cdf404",
        username: "wasabi",
        user_id: nil
      },
      channel_title: "Adam Bub",
      description:
        "I created this video with the YouTube Slideshow Creator (http://www.youtube.com/upload)",
      next: "",
      img_height: 90,
      img_url: "https://i.ytimg.com/vi/qu_uJQQo_Us/default.jpg",
      img_width: 120,
      is_queued: false,
      previous: "FJ5pRIZXVks",
      video_id: "qu_uJQQo_Us",
      title: "3 second video"
    }
  ]

  def room_queue do
    for video <- @room_queue do
      CollectionsFixtures.video_fixture(%{
        channel_title: video.channel_title,
        description: video.description,
        img_height: "#{video.img_height}",
        img_url: video.img_url,
        img_width: "#{video.img_width}",
        title: video.title,
        video_id: video.video_id
      })
    end

    @room_queue
  end

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
        queue: room_queue()
      })
      |> LiveDj.Organizer.create_room()

    # Creates a playlist, generates the proper playlist video relationships and
    # associates the playlist to this room
    {:ok, playlist} = Collections.create_playlist()

    for {video, index} <- Enum.with_index(room.queue) do
      video =
        Map.merge(video, %{
          position: index,
          added_by_user_id: video.added_by.user_id
        })

      Collections.cast_playlist_video(video, playlist.id)
    end
    |> Collections.create_or_update_playlists_videos()

    {:ok, room} = LiveDj.Organizer.assoc_playlist(room, playlist)
    room
  end

  def user_room_fixture(
        attrs \\ %{},
        user_attrs \\ %{},
        room_attrs \\ %{},
        group_attrs \\ %{}
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
