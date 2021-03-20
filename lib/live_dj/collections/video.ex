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
end
