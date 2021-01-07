alias LiveDj.Repo
alias LiveDj.Seeds.Utils
alias LiveDj.Stats.Badge

try do
  badges = System.get_env("LIVEDJ_BADGES")
    |> Poison.decode!()
    |> Enum.with_index()
    |> Enum.map(fn {badge, index} -> %{
      id: index + 1,
      name: badge["name"],
      description: badge["description"],
      icon: badge["icon"],
      inserted_at: Utils.date_to_naive_datetime(badge["inserted_at"]),
      updated_at: Utils.date_to_naive_datetime(badge["inserted_at"])
    } end)

  {count, _} = Repo.insert_all(Badge, badges)
  IO.inspect("Inserted #{count} badges.")

rescue
  Postgrex.Error ->
    IO.inspect("Badge seeds were already loaded in the database. Skipping execution.")
  error ->
    IO.inspect("Unexpected error while loading Badge seeds.")
    IO.inspect(error)
end
