defmodule LiveDj.Accounts.UserRoom do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_rooms" do
    field :is_owner, :boolean, default: false
    belongs_to :user, LiveDj.Accounts.User
    belongs_to :room, LiveDj.Organizer.Room

    timestamps()
  end

  @doc false
  def changeset(user_room, attrs) do
    user_room
    |> cast(attrs, [:user_id, :room_id, :is_owner])
    |> validate_required([:user_id, :room_id, :is_owner])
  end
end
