Code.require_file("utils.exs", __DIR__)

require Logger

alias LiveDj.Repo
alias LiveDj.Collections.Video
alias LiveDj.Organizer

schema_upper = "Video"
schema_plural = "videos"

json_file = "#{__DIR__}/videos.json"

try do
  # with {:ok, body} <- File.read(json_file),
  #   {:ok, videos} <- Jason.decode(body, keys: :atoms) do

  #   date_keys = [:inserted_at, :updated_at]
  #   videos = Enum.map(videos, fn video ->
  #     Map.merge(
  #       video,
  #       Utils.dates_to_naive_datetime(video, date_keys)
  #     )
  #   end)
  #   {count, _} = Repo.insert_all(Video, videos)
  #   count
  # end

  videos = List.flatten(Enum.map(Organizer.list_rooms(), fn room -> room.queue end))

  {unique_videos, _} = Enum.reduce(videos, {[], []}, fn (video, {result, unique}) ->
    case Enum.member?(unique, video["video_id"]) do
      false -> {result ++ [video], unique ++ [video["video_id"]]}
      true -> {result, unique}
    end
  end)

  Enum.map(unique_videos, fn video ->
    {:ok, video} = %Video{
      channel_title: HtmlEntities.decode(video["channel_title"]),
      description: HtmlEntities.decode(video["description"]),
      img_height: Integer.to_string(video["img_height"]),
      img_url: video["img_url"],
      img_width: Integer.to_string(video["img_width"]),
      title: HtmlEntities.decode(video["title"]),
      video_id: video["video_id"],
    } |> Repo.insert()
    video
  end)
rescue
  Postgrex.Error ->
    Logger.info("#{schema_upper} seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.info("❌ Unexpected error while loading #{schema_upper} seeds.")
    Logger.info(error)
    raise error
else
  elements ->
    Logger.info("✅ Inserted #{length(elements)} #{schema_plural}.")
end
