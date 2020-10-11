defmodule LiveDj.Organizer.Video do

  alias LiveDj.Organizer.Video

  defstruct channel_title: "", description: "", img_height: "", img_url: "", img_width: "", is_queued: "", title: "", video_id: "", previous: "", next: ""

  def update(video, props) do
    Map.merge(video, props)
  end

  def from_tubex_video(tubex_video) do
    %Video{
      channel_title: tubex_video.channel_title,
      img_url: tubex_video.thumbnails["default"]["url"],
      img_height: tubex_video.thumbnails["default"]["height"],
      img_width: tubex_video.thumbnails["default"]["width"],
      is_queued: "",
      description: tubex_video.description,
      title: tubex_video.title,
      video_id: tubex_video.video_id,
      previous: "",
      next: "",
    }
  end
end
