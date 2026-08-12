defmodule Livedj.Repo.Migrations.AddPasswordHashToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :password_hash, :string
    end
  end
end
