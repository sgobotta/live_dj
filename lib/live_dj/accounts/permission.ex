defmodule LiveDj.Accounts.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :codename, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :codename])
    |> validate_required([:name, :codename])
  end

  def has_permission(permissions, permission) do
    Enum.any?(permissions, fn p -> p.codename == permission end)
  end
end
