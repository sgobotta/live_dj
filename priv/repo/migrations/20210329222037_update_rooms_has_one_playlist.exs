defmodule LiveDj.Repo.Migrations.UpdateRoomsHasOnePlaylist do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :playlist_id, references(:playlists)
    end

    create unique_index(:rooms, [:playlist_id])
  end
end
