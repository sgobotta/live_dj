defmodule LiveDj.Collections.PlaylistVideo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "playlists_videos" do
    belongs_to :added_by_user, LiveDj.Accounts.User
    belongs_to :playlist, LiveDj.Collections.Playlist
    belongs_to :video, LiveDj.Collections.Video

    belongs_to :previous_video, LiveDj.Collections.Video
    belongs_to :next_video, LiveDj.Collections.Video

    timestamps()
  end

  @doc false
  def changeset(playlist_video, attrs) do
    playlist_video
    |> cast(attrs, [:added_by_user_id, :playlist_id, :video_id, :previous_video_id, :next_video_id])
    |> validate_required([:playlist_id, :video_id])
  end
end
