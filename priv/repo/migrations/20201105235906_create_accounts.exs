defmodule LiveDj.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :uuid, :string
      add :username, :string

      timestamps()
    end

    create unique_index(:accounts, :uuid)
  end
end
