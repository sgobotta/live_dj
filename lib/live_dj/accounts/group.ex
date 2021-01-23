defmodule LiveDj.Accounts.Group do
  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :codename, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:codename, :name])
    |> validate_required([:codename, :name])
  end
end
