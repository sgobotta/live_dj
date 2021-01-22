defmodule LiveDj.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :name, :string
      add :codename, :string

      timestamps()
    end

  end
end
