require Logger

alias LiveDj.Collections

schema_upper = "UserVideo"
schema_plural = "user videos"

try do
  # Assumes Users and Videos were created
  # {user_id, video_id}
  [
    {1,  1},
    {1,  2},
    {1,  3},
    {1,  4},
    {1,  5},
    {1,  6},

    {2,  1},
    {2,  2},
    {2,  3},
    {2,  4},
    {2,  5},
    {2,  6},

    {3,  1},
    {3,  2},
    {3,  3},
    {3,  4},
    {3,  5},
    {3,  6},

    {4,  1},

    {5,  1},

    {6,  6},
  ]
  |> Enum.map(
      fn {user_id, video_id} ->
        {:ok, _} = Collections.create_user_video(%{
          user_id: user_id,
          video_id: video_id,
        })
      end
    )
rescue
  Postgrex.Error ->
    Logger.info("#{schema_upper} seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.error("❌ Unexpected error while loading #{schema_upper} seeds.")
    Logger.error(error)
    raise error
else
  elements ->
    Logger.info("✅ Inserted #{length(elements)} #{schema_plural} relationships.")
end
