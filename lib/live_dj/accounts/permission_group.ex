defmodule LiveDj.Accounts.PermissionGroup do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions_groups" do
    belongs_to :permission, LiveDj.Accounts.Permission
    belongs_to :group, LiveDj.Accounts.Group

    timestamps()
  end

  @doc false
  def changeset(permission_group, attrs) do
    permission_group
    |> cast(attrs, [:permission_id, :group_id])
    |> validate_required([:permission_id, :group_id])
  end
end
