defmodule LiveDj.Payments.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plans" do
    field :amount, :float
    field :gateway, :string
    field :name, :string
    field :plan_id, :string
    field :type, :string
    field :extra, {:array, :map}, default: []

    timestamps()
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:gateway, :plan_id, :amount, :type, :name, :extra])
    |> validate_required([:gateway, :plan_id, :amount, :type, :name])
  end
end
