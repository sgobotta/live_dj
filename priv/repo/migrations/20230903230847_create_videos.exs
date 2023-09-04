defmodule Livedj.Repo.Migrations.CreateVideos do
  use Ecto.Migration

  def change do
    create table(:videos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :url, :string
      add :thumbnail_url, :string
      add :external_id, :string
      add :etag, :string
      add :published_at, :naive_datetime

      timestamps()
    end
  end
end
