defmodule LiveDj.Repo.Migrations.UpdateUsersRoomsGroupsReference do
  use Ecto.Migration

  def change do
    alter table(:users_rooms) do
      add :group_id, references(:groups, on_delete: :nothing)
    end
  end
end
