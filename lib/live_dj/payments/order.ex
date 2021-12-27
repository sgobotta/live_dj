defmodule LiveDj.Payments.Order do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "orders" do
    belongs_to :user, LiveDj.Accounts.User
    belongs_to :plan, LiveDj.Payments.Plan
    field :amount, :float

    timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:amount, :plan_id, :user_id])
    |> validate_required([:amount, :plan_id])
  end
end
