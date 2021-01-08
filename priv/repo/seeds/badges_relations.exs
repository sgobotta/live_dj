alias LiveDj.Stats

try do
  badges_users = [{1, 1}, {1, 2}]
  |> Enum.map(fn {user_id, badge_id} ->
    :ok = Stats.assoc_user_badge(user_id, badge_id)
  end)

  IO.inspect("Inserted #{length(badges_users)} user/badge relationships.")

rescue
  Postgrex.Error ->
    IO.inspect("UserBadge seeds were already loaded in the database. Skipping execution.")
  error ->
    IO.inspect("Unexpected error while loading UserBadge seeds.")
    IO.inspect(error)
end
