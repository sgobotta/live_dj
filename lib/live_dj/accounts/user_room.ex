defmodule LiveDj.Accounts.UserRoom do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveDj.Accounts.User
  alias LiveDj.Organizer.Room

  schema "users_rooms" do
    field :is_owner, :boolean, default: false
    belongs_to :user, User
    belongs_to :room, Room

    timestamps([{:updated_at, false}])
  end

  @doc false
  def changeset(user_room, attrs) do
    user_room
    |> cast(attrs, [:user_id, :room_id])
    |> validate_required([:user_id, :room_id])
  end
end
