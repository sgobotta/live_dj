defmodule LiveDj.Organizer.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :slug, :string
    field :title, :string

    timestamps()
  end

  @fields [:title, :slug]

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, @fields)
    |> validate_required([:title, :slug])
    |> format_slug()
    |> unique_constraint(:slug)
  end

  defp format_slug(%Ecto.Changeset{changes: %{slug: _}} = changeset) do
    changeset
    |> update_change(:slug, fn slug ->
      slug
      |> String.downcase()
      |> String.replace(" ", "-")
    end)
  end
  defp format_slug(changeset), do: changeset
end
