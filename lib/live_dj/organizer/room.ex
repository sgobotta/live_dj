defmodule LiveDj.Organizer.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :queue, {:array, :map}, default: "[]"
    field :slug, :string
    field :title, :string
    field :video_tracker, :string, default: ""

    timestamps()
  end

  @fields [:queue, :slug, :title, :video_tracker]

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
