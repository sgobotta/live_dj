defmodule LiveDj.Repo.Migrations.CreateUsersRooms do
  use Ecto.Migration

  def change do
    create table(:users_rooms) do
      add :is_owner, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :nothing)
      add :room_id, references(:rooms, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:users_rooms, [:room_id, :user_id])
  end
end
