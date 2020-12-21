defmodule LiveDj.Payments.Order do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    belongs_to :user, LiveDj.Accounts.User
    belongs_to :plan, LiveDj.Payments.Plan

    timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:plan_id, :user_id])
    |> validate_required([:plan_id])
  end
end
