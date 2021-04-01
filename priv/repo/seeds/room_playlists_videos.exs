require Logger

alias LiveDj.Collections
alias LiveDj.Organizer
alias LiveDj.Repo

primary_schema_upper = "PlaylistVideo"
primary_schema_plural = "playlists videos"

secondary_schema_upper = "Room"
secondary_schema_plural = "rooms"

try do
  get_video_by = fn id ->
    v_id = case Repo.get_by(Collections.Video, %{video_id: id}) do
      nil -> nil
      v -> v.id
    end
  end

  rooms_videos = Organizer.list_rooms()
  |> Enum.map(fn room ->
    videos = Enum.map(Enum.with_index(room.queue), fn {video, index} ->
      {index, video["video_id"], video["previous"], video["next"],
        video["added_by"]["username"]}
    end)
    {Repo.preload(room, [:playlist]), videos}
  end)
  room_playlists_videos = for {room, videos} <- rooms_videos do
    playlist_video = for {position, video_id, previous_video_id, next_video_id, _added_by} <- videos do
      v_id = get_video_by.(video_id)
      p_id = get_video_by.(previous_video_id)
      n_id = get_video_by.(next_video_id)

      {:ok, playlist_video} = Collections.create_playlist_video(%{
        added_by_user_id: nil,
        playlist_id: room.playlist.id,
        position: position,
        video_id: v_id,
        previous_video_id: p_id,
        next_video_id: n_id
      })
      playlist_video
    end
    {room, playlist_video}
  end
  room_playlists_videos
rescue
  Postgrex.Error ->
    Logger.info("#{primary_schema_plural} for #{secondary_schema_plural} seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.error("❌ Unexpected error while loading #{primary_schema_upper} for #{secondary_schema_upper} relation seeds.")
    Logger.error(error)
    raise error
else
  room_playlists_videos ->
    {rooms, playlists_videos} = Enum.reduce(room_playlists_videos, {0, 0}, fn ({_room, playlists_videos}, {rooms_count, playlists_videos_count}) ->
      {rooms_count + 1, playlists_videos_count + length(playlists_videos)}
    end)
    Logger.info("✅ Updated #{playlists_videos} #{primary_schema_plural} reationships from #{rooms} #{secondary_schema_plural}.")
end
