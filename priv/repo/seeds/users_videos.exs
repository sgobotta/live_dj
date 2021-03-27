require Logger

alias LiveDj.Accounts.User
alias LiveDj.Collections
alias LiveDj.Repo

schema_upper = "UserVideo"
schema_plural = "user videos"

try do
  # Assumes Users and Videos were created
  users = Repo.all(User) |> Enum.map(fn u -> u.id end)
  videos = Collections.list_videos() |> Enum.map(fn v -> v.id end)

  # [{user_id, video_id}]
  for u <- users do
    evens = Enum.filter(videos, fn e -> rem(e, 2) == 0 end)
    odds = Enum.filter(videos, fn e -> rem(e, 2) == 0 end)
    all = videos

    videos_length = length(videos)
    a_quarter_videos = trunc(videos_length / 4)
    first_quarter = Enum.slice(videos, 0, a_quarter_videos * 2)
    second_and_third_quarter = Enum.slice(videos, a_quarter_videos, a_quarter_videos * 2)

    case u do
      1 -> for v <- evens, do: {u, v}
      2 -> for v <- odds, do: {u, v}
      3 -> for v <- all, do: {u, v}
      4 -> for v <- first_quarter, do: {u, v}
      5 -> for v <- second_and_third_quarter, do: {u, v}
      _ -> []
    end
  end
  |> List.flatten()
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
