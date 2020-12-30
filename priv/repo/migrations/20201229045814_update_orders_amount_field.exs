defmodule LiveDj.Repo.Migrations.UpdateOrdersAmountField do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :amount, :float
    end
  end
end
