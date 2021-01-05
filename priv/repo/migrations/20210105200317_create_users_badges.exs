defmodule LiveDj.Repo.Migrations.CreateUsersBadges do
  use Ecto.Migration

  def change do
    create table(:users_badges) do
      add :user_id, references(:users)
      add :badge_id, references(:badges)
    end

    create unique_index(:users_badges, [:user_id, :badge_id])
  end
end
