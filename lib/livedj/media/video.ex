defmodule Livedj.Media.Video do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import LivedjWeb.Gettext

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "videos" do
    field :etag, :string
    field :external_id, :string
    field :published_at, :naive_datetime
    field :thumbnail_url, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :title,
      :thumbnail_url,
      :external_id,
      :etag,
      :published_at
    ])
    |> validate_required([
      :title,
      :thumbnail_url,
      :external_id,
      :etag,
      :published_at
    ])
    |> unique_constraint(:external_id,
      message: dgettext("errors", "video with this id already exists")
    )
  end
end
