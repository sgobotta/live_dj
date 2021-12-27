defmodule LiveDj.Accounts.Group do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :codename, :string
    field :name, :string

    has_many :users_rooms, LiveDj.Organizer.UserRoom

    many_to_many :permissions, LiveDj.Accounts.Permission,
      join_through: LiveDj.Accounts.PermissionGroup

    timestamps()
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:codename, :name])
    |> validate_required([:codename, :name])
  end
end
