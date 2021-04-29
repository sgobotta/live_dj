defmodule LiveDj.Collections.Playlist do
  use Ecto.Schema
  import Ecto.Changeset

  alias LiveDj.Collections.{PlaylistVideo, Video}

  schema "playlists" do
    has_one :room, LiveDj.Organizer.Room
    many_to_many :videos, Video, join_through: PlaylistVideo

    timestamps()
  end

  @doc false
  def changeset(playlist, attrs) do
    playlist
    |> cast(attrs, [])
    |> validate_required([])
  end
end
