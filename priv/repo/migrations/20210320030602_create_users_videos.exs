defmodule LiveDj.Repo.Migrations.CreateUsersVideos do
  use Ecto.Migration

  def change do
    create table(:users_videos) do
      add :user_id, references(:users, on_delete: :nothing)
      add :video_id, references(:videos, on_delete: :nothing)

      timestamps()
    end

    create index(:users_videos, [:user_id])
    create index(:users_videos, [:video_id])
  end
end
