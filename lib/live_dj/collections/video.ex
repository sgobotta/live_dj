defmodule LiveDj.Collections.Video do
  use Ecto.Schema
  import Ecto.Changeset

  schema "videos" do
    field :channel_title, :string
    field :description, :string
    field :img_height, :string
    field :img_url, :string
    field :img_width, :string
    field :title, :string
    field :video_id, :string

    timestamps()
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [:channel_title, :description, :img_height, :img_url, :img_width, :title, :video_id])
    |> validate_required([:channel_title, :description, :img_height, :img_url, :img_width, :title, :video_id])
    |> unique_constraint(:video_id)
  end

  def from_tubex(video) do
    %{
      channel_title: HtmlEntities.decode(video.channel_title),
      description: HtmlEntities.decode(video.description),
      img_height: Integer.to_string(video.img_height),
      img_url: video.img_url,
      img_width: Integer.to_string(video.img_width),
      title: HtmlEntities.decode(video.title),
      video_id: video.video_id,
    }
  end
end
