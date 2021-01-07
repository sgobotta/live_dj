defmodule LiveDj.Accounts.UserBadge do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveDj.Accounts.User
  alias LiveDj.Stats.Badge

  schema "users_badges" do
    belongs_to :user, User
    belongs_to :badge, Badge

    timestamps([{:updated_at, false}])
  end

  @doc false
  def changeset(user_badge, attrs) do
    user_badge
    |> cast(attrs, [:user_id, :badge_id])
    |> validate_required([:user_id, :badge_id])
  end
end
