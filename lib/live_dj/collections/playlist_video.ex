defmodule LiveDj.Collections.PlaylistVideo do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "playlists_videos" do
    field :position, :integer

    belongs_to :user, LiveDj.Accounts.User, foreign_key: :added_by_user_id
    belongs_to :playlist, LiveDj.Collections.Playlist
    belongs_to :video, LiveDj.Collections.Video

    belongs_to :previous_video, LiveDj.Collections.Video
    belongs_to :next_video, LiveDj.Collections.Video

    timestamps()
  end

  @doc false
  def changeset(playlist_video, attrs) do
    playlist_video
    |> cast(attrs, [
      :added_by_user_id,
      :next_video_id,
      :playlist_id,
      :position,
      :previous_video_id,
      :video_id
    ])
    |> validate_required([:playlist_id, :position, :video_id])
  end
end
