defmodule LiveDj.Repo.Migrations.CreateUsersRooms do
  use Ecto.Migration

  def change do
    create table(:users_rooms) do
      add :is_owner, :boolean, default: false
      add :user_id, references(:users)
      add :room_id, references(:rooms)

      timestamps([{:updated_at, false}])
    end

    create unique_index(:users_rooms, [:user_id, :room_id])
  end
end
