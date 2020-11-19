defmodule LiveDj.Notifications do
  @moduledoc """
  The Notifications context.
  """

  def create(:play_video, video) do
    %{
      img: video.img_url,
      title: video.title
    }
  end
end
