defmodule LiveDj.Repo.Migrations.CreatePlans do
  use Ecto.Migration

  def change do
    create table(:plans) do
      add :gateway, :string
      add :plan_id, :string
      add :amount, :float
      add :type, :string
      add :name, :string

      timestamps()
    end

  end
end
