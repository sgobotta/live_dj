defmodule LiveDj.Notifications do
  @moduledoc """
  The Notifications context.
  """

  def create(:play_video, video, tag) do
    %{
      img: %{is_remote: true, value: video.img_url},
      title: "LiveDj\nPlaying: #{video.title}",
      tag: tag
    }
  end

  def create(:registered_user,
    %{badge_icon: badge_icon, badge_name: badge_name, username: username}
  ) do
    %{
      img: %{is_remote: false, value: "badges/#{badge_icon}.png"},
      title: "LiveDj\nWelcome, #{username}! You have just received the \"#{badge_name}\" badge!",
      tag: "registered-user"
    }
  end

  def create(:receive_badge, %{badge_icon: badge_icon, badge_name: badge_name}) do
    %{
      img: %{is_remote: false, value: "badges/#{badge_icon}.png"},
      title: "LiveDj\nCongratulations, you just received the \"#{badge_name}\" badge!",
      tag: "receive-badge"
    }
  end
end
