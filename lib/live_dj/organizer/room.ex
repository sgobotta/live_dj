defmodule LiveDj.Organizer.Room do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias LiveDj.Collections.Playlist

  schema "rooms" do
    field :queue, {:array, :map}, default: []
    field :slug, :string
    field :title, :string
    field :video_tracker, :string, default: ""
    field :management_type, :string, default: "free"

    belongs_to :playlist, Playlist

    many_to_many :users, LiveDj.Accounts.User,
      join_through: LiveDj.Organizer.UserRoom

    timestamps()
  end

  @fields [:management_type, :queue, :slug, :title, :video_tracker]

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, @fields)
    |> cast_assoc(:playlist, with: &Playlist.changeset/2)
    |> validate_required([:slug, :title])
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
