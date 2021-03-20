Code.require_file("utils.exs", __DIR__)

require Logger

alias LiveDj.Repo
alias LiveDj.Collections.Video
alias LiveDj.Seeds.Utils

schema_upper = "Video"
schema_plural = "videos"

json_file = "#{__DIR__}/videos.json"

try do
  with {:ok, body} <- File.read(json_file),
    {:ok, videos} <- Jason.decode(body, keys: :atoms) do

    date_keys = [:inserted_at, :updated_at]
    videos = Enum.map(videos, fn video ->
      Map.merge(
        video,
        Utils.dates_to_naive_datetime(video, date_keys)
      )
    end)
    {count, _} = Repo.insert_all(Video, videos)
    count
  end
rescue
  Postgrex.Error ->
    Logger.info("#{schema_upper} seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.info("❌ Unexpected error while loading #{schema_upper} seeds.")
    Logger.info(error)
    raise error
else
  count ->
    Logger.info("✅ Inserted #{count} #{schema_plural}.")
end
