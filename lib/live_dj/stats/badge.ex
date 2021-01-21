defmodule LiveDj.Stats.Badge do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveDj.Stats.UserBadge

  schema "badges" do
    field :description, :string
    field :icon, :string
    field :name, :string
    field :reference_name, :string
    field :type, :string
    field :checkpoint, :integer

    many_to_many :users, LiveDj.Accounts.User, join_through: UserBadge

    timestamps()
  end

  @doc false
  def changeset(badge, attrs) do
    badge
    |> cast(attrs, [:description, :icon, :name, :reference_name, :type, :checkpoint])
    |> validate_required([:description, :icon, :name, :reference_name, :type, :checkpoint])
  end
end
