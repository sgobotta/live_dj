defmodule LiveDj.Organizer.UserRoom do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "users_rooms" do
    field :is_owner, :boolean, default: false

    belongs_to :user, LiveDj.Accounts.User
    belongs_to :room, LiveDj.Organizer.Room
    belongs_to :group, LiveDj.Accounts.Group

    timestamps()
  end

  @doc false
  def changeset(user_room, attrs) do
    user_room
    |> cast(attrs, [:user_id, :room_id, :group_id, :is_owner])
    |> validate_required([:user_id, :room_id, :group_id, :is_owner])
  end
end
