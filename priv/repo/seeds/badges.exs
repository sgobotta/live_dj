alias LiveDj.Repo
alias LiveDj.Stats.Badge

try do
  badges = System.get_env("LIVEDJ_BADGES")
    |> Poison.decode!()
    |> Enum.map(fn badge ->
      {:ok, date_time} = Ecto.Type.cast(:naive_datetime, badge["inserted_at"])
      %Badge{
        description: badge["description"],
        icon: badge["icon"],
        name: badge["name"],
        reference_name: badge["reference_name"],
        inserted_at: date_time,
        updated_at: date_time
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
