defmodule LiveDj.Repo.Migrations.CreatePlaylistsVideos do
  use Ecto.Migration

  def change do
    create table(:playlists_videos) do
      add :position, :integer, null: false

      add :playlist_id, references(:playlists, on_delete: :nothing)
      add :video_id, references(:videos, on_delete: :nothing)
      add :added_by_user_id, references(:users, on_delete: :nothing)

      add :previous_video_id, references(:videos, on_delete: :nothing)
      add :next_video_id, references(:videos, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:playlists_videos, [:playlist_id, :position, :video_id])
  end
end
