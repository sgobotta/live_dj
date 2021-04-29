defmodule LiveDj.CollectionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Collections` context.
  """

  alias LiveDj.AccountsFixtures
  alias LiveDj.Collections

  @videos [
    %{
      channel_title: "bvbb",
      description: "my cat is epic.",
      img_height: "90",
      img_url: "https://i.ytimg.com/vi/wUF9DeWJ0Dk/default.jpg",
      img_width: "120",
      title: "Video Countdown 3 seconds",
      video_id: "wUF9DeWJ0Dk"
    },
    %{
      channel_title: "Bảo Anh",
      description: "",
      img_height: "90",
      img_url: "https://i.ytimg.com/vi/dyp2mLYhRkw/default.jpg",
      img_width: "120",
      title: "Video Countdown 20 Old  3 seconds",
      video_id: "dyp2mLYhRkw"
    },
    %{
      channel_title: "Bảo Anh",
      description: "",
      img_height: "90",
      img_url: "https://i.ytimg.com/vi/dyp2mLYhRkw/default.jpg",
      img_width: "120",
      title: "Video Countdown 20 Old  3 seconds",
      video_id: "dyp2mLYhRkw"
    },
    %{
      channel_title: "DiaryBela",
      description:
        "If you read this far down the description I love you. Please Hit that ▷ SUBSCRIBE button and LIKE my video and also turn ON notifications BELL! FOLLOW ...",
      img_height: 90,
      img_url: "https://i.ytimg.com/vi/FJ5pRIZXVks/default.jpg",
      img_width: 120,
      title: "#1 Countdown | 3 seconds with sound effect",
      video_id: "FJ5pRIZXVks"
    },
    %{
      channel_title: "Adam Bub",
      description:
        "I created this video with the YouTube Slideshow Creator (http://www.youtube.com/upload)",
      img_height: 90,
      img_url: "https://i.ytimg.com/vi/qu_uJQQo_Us/default.jpg",
      img_width: 120,
      title: "3 second video",
      video_id: "qu_uJQQo_Us"
    }
  ]

  def videos, do: @videos

  def videos_fixture do
    for _n <- 0..length(@videos) do
      video_fixture()
    end
  end

  def playlist_fixture(attrs \\ %{}) do
    {:ok, playlist} =
      attrs
      |> Enum.into(%{})
      |> Collections.create_playlist()

    playlist
  end

  def video_fixture(attrs \\ %{}) do
    video = Enum.at(@videos, 0)

    {:ok, video} =
      attrs
      |> Enum.into(video)
      |> Collections.create_video()

    video
  end

  def user_video_fixture(attrs \\ %{}, user_attrs \\ %{}, video_attrs \\ %{}) do
    user = AccountsFixtures.user_fixture(user_attrs)
    video = video_fixture(video_attrs)

    {:ok, user_video} =
      attrs
      |> Enum.into(%{video_id: video.id, user_id: user.id})
      |> LiveDj.Organizer.create_user_room()

    %{video: video, user: user, user_video: user_video}
  end
end
