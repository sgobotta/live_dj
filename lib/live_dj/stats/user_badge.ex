defmodule LiveDj.Stats.UserBadge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_badges" do
    belongs_to :user, LiveDj.Accounts.User
    belongs_to :badge, LiveDj.Stats.Badge

    timestamps([{:updated_at, false}])
  end

  @doc false
  def changeset(user_badge, attrs) do
    user_badge
    |> cast(attrs, [:user_id, :badge_id])
    |> validate_required([:user_id, :badge_id])
  end
end
