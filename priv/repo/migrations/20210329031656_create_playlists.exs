defmodule LiveDj.Repo.Migrations.CreatePlaylists do
  use Ecto.Migration

  def change do
    create table(:playlists) do

      timestamps()
    end

  end
end
