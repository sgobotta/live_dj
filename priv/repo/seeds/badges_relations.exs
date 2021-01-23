alias LiveDj.Stats

try do
  badges_users = [
    {1, "users-confirmed_via_link"},
    {1, "rooms-create_once"},
    {2, "rooms-create_once"}
  ]
  |> Enum.map(fn {user_id, badge_reference_name} ->
    :ok = Stats.assoc_user_badge(user_id, badge_reference_name)
  end)

  IO.inspect("Inserted #{length(badges_users)} user/badge relationships.")

rescue
  Postgrex.Error ->
    IO.inspect("UserBadge seeds were already loaded in the database. Skipping execution.")
  error ->
    IO.inspect("Unexpected error while loading UserBadge seeds.")
    IO.inspect(error)
    raise error
end
