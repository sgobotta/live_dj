defmodule LiveDj.Organizer.Video do

  alias LiveDj.Organizer.Video

  defstruct img_height: "", img_url: "", img_width: "", is_queued: false, title: "", video_id: "", previous: "", next: ""

  def create(props) do
    %Video{
      img_height: props["img_height"],
      img_url: props["img_url"],
      img_width: props["img_width"],
      is_queued: false,
      title: props["title"],
      video_id: props["video_id"],
      previous: "",
      next: ""
    }
  end
end
