defmodule LiveDj.Repo.Migrations.CreateVideos do
  use Ecto.Migration

  def change do
    create table(:videos) do
      add :channel_title, :string
      add :description, :string
      add :img_height, :string
      add :img_url, :string
      add :img_width, :string
      add :title, :string
      add :video_id, :string

      timestamps()
    end

  end
end
