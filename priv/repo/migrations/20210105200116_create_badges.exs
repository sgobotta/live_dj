defmodule LiveDj.Repo.Migrations.CreateBadges do
  use Ecto.Migration

  def change do
    create table(:badges) do
      add :name, :string, null: false
      add :description, :string, null: false
      add :icon, :string, null: false
      add :reference_name, :string, null: false

      timestamps()
    end

    create unique_index(:badges, [:reference_name])
  end
end
