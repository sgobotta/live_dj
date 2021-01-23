alias LiveDj.Repo
alias LiveDj.Stats.Badge

require Logger

try do
  System.get_env("LIVEDJ_BADGES")
    |> Poison.decode!()
    |> Enum.map(fn badge ->
      {:ok, date_time} = Ecto.Type.cast(:naive_datetime, badge["inserted_at"])
      %Badge{
        description: badge["description"],
        icon: badge["icon"],
        name: badge["name"],
        reference_name: badge["reference_name"],
        type: badge["type"],
        checkpoint: badge["checkpoint"],
        inserted_at: date_time,
        updated_at: date_time
      }
      |> Repo.insert()
    end)
rescue
  Postgrex.Error ->
    Logger.info("Badge seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.error("❌ Unexpected error while loading Badge seeds.")
    Logger.error(error)
    raise error
else
  elements ->
    Logger.info("✅ Inserted #{length(elements)} badges.")
end
