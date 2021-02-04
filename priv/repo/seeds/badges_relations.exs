alias LiveDj.Stats

require Logger

try do
  [
    {1, "users-confirmed_via_link"},
    {1, "rooms-create_once"},
    {2, "rooms-create_once"}
  ]
  |> Enum.map(fn {user_id, badge_reference_name} ->
    :ok = Stats.assoc_user_badge(user_id, badge_reference_name)
  end)
rescue
  Postgrex.Error ->
    Logger.info("UserBadge seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.error("❌ Unexpected error while loading UserBadge seeds.")
    Logger.error(error)
    raise error
else
  elements ->
    Logger.info("✅ Inserted #{length(elements)} user/badge relationships.")
end
