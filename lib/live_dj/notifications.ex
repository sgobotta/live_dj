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

  def create(:receive_badge, %{badge_icon: badge_icon, badge_name: badge_name}) do
    %{
      img: %{is_remote: false, value: "badges/#{badge_icon}.png"},
      title:
        "LiveDj\nCongratulations, you just received the \"#{badge_name}\" badge!",
      tag: "receive-badge"
    }
  end
end
