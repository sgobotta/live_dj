alias LiveDj.Repo
alias LiveDj.Seeds.Utils
alias LiveDj.Stats.Badge

try do
  badges = System.get_env("LIVEDJ_BADGES")
    |> Poison.decode!()
    |> Enum.map(fn badge ->
      %Badge{
        description: badge["description"],
        icon: badge["icon"],
        name: badge["name"],
        reference_name: badge["reference_name"],
        inserted_at: Utils.date_to_naive_datetime(badge["inserted_at"]),
        updated_at: Utils.date_to_naive_datetime(badge["inserted_at"])
      }
      |> Repo.insert()
    end)

  IO.inspect("Inserted #{length(badges)} badges.")

rescue
  Postgrex.Error ->
    IO.inspect("Badge seeds were already loaded in the database. Skipping execution.")
  error ->
    IO.inspect("Unexpected error while loading Badge seeds.")
    IO.inspect(error)
end
