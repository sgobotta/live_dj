defmodule LiveDj.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :user_id, references(:users, on_delete: :nothing)
      add :plan_id, references(:plans, on_delete: :nothing)

      timestamps()
    end

    create index(:orders, [:user_id])
    create index(:orders, [:plan_id])
  end
end
