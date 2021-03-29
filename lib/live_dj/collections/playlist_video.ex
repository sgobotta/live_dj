defmodule LiveDj.Collections.PlaylistVideo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "playlists_videos" do
    belongs_to :user, LiveDj.Accounts.User
    belongs_to :playlist, LiveDj.Collections.Playlist
    belongs_to :video, LiveDj.Collections.Video

    timestamps()
  end

  @doc false
  def changeset(playlist_video, attrs) do
    playlist_video
    |> cast(attrs, [:user_id, :playlist_id, :video_id])
    |> validate_required([])
  end
end
