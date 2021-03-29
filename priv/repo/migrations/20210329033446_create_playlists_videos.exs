defmodule LiveDj.Repo.Migrations.CreatePlaylistsVideos do
  use Ecto.Migration

  def change do
    create table(:playlists_videos) do
      add :playlist_id, references(:playlists, on_delete: :nothing)
      add :video_id, references(:videos, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:playlists_videos, [:playlist_id, :video_id])
  end
end