defmodule LiveDj.Organizer.Account do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts" do
    field :uuid, :string
    field :username, :string

    timestamps()
  end

  @fields [:uuid, :username]

  def changeset(account, attrs) do
    account
    |> cast(attrs, @fields)
    |> validate_required([:uuid, :username])
    |> unique_constraint(:uuid)
  end
end
