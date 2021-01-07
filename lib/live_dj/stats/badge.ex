defmodule LiveDj.Stats.Badge do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveDj.Accounts.UserBadge

  schema "badges" do
    field :description, :string
    field :icon, :string
    field :name, :string

    many_to_many :users, LiveDj.Accounts.User, join_through: UserBadge

    timestamps()
  end

  @doc false
  def changeset(badge, attrs) do
    badge
    |> cast(attrs, [:name, :description, :icon])
    |> validate_required([:name, :description, :icon])
  end
end
