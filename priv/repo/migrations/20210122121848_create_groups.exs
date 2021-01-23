defmodule LiveDj.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :name, :string, null: false
      add :codename, :string, null: false

      timestamps()
    end

    create unique_index(:groups, [:name, :codename])
  end
end
