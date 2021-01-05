defmodule LiveDj.Stats.Badge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "badges" do
    field :description, :string
    field :icon, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(badge, attrs) do
    badge
    |> cast(attrs, [:name, :description, :icon])
    |> validate_required([:name, :description, :icon])
  end
end
