alias LiveDj.Repo
alias LiveDj.Accounts.Permission

schema_upper = "Permission"
schema_plural = "permissions"
env_var = "LIVEDJ_PERMISSIONS"

try do
  elements = System.get_env(env_var)
    |> Poison.decode!()
    |> Enum.map(fn e ->
      %Permission{
        id: e["id"],
        codename: e["codename"],
        name: e["name"]
      }
      |> Repo.insert()
    end)

  IO.inspect("Inserted #{length(elements)} #{schema_plural}.")

rescue
  Postgrex.Error ->
    IO.inspect("#{schema_upper} seeds were already loaded in the database. Skipping execution.")
  error ->
    IO.inspect("Unexpected error while loading #{schema_upper} seeds.")
    IO.inspect(error)
    raise error
end
