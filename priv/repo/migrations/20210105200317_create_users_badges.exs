defmodule LiveDj.Repo.Migrations.CreateUsersBadges do
  use Ecto.Migration

  def change do
    create table(:users_badges) do
      add :user_id, references(:users)
      add :badge_id, references(:badges)

      timestamps([{:updated_at, false}])
    end

    create unique_index(:users_badges, [:user_id, :badge_id])
  end
end
