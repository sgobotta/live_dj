defmodule LiveDj.Repo.Migrations.CreatePermissionsGroups do
  use Ecto.Migration

  def change do
    create table(:permissions_groups) do
      add :permission_id, references(:permissions, on_delete: :nothing), null: false
      add :group_id, references(:groups, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:permissions_groups, [:permission_id, :group_id])
  end
end
