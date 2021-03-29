defmodule LiveDj.Collections.Playlist do
  use Ecto.Schema
  import Ecto.Changeset

  schema "playlists" do

    timestamps()
  end

  @doc false
  def changeset(playlist, attrs) do
    playlist
    |> cast(attrs, [])
    |> validate_required([])
  end
end
