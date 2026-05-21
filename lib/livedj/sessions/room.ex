defmodule Livedj.Sessions.Room do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :name, :string
    field :slug, :string

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> maybe_put_slug()
  end

  defp maybe_put_slug(%Ecto.Changeset{data: %{slug: nil}} = changeset) do
    put_change(changeset, :slug, Ecto.UUID.generate())
  end

  defp maybe_put_slug(changeset), do: changeset
end
