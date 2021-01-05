defmodule LiveDj.Repo.Migrations.CreateBadges do
  use Ecto.Migration

  def change do
    create table(:badges) do
      add :name, :string
      add :description, :string
      add :icon, :string

      timestamps()
    end

  end
end
