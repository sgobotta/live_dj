alias LiveDj.Repo
alias LiveDj.Accounts.PermissionGroup

schema_upper = "PermissionGroup"
schema_plural = "permissions_groups"
env_var = "LIVEDJ_PERMISSIONS_GROUPS"

try do
  elements = System.get_env(env_var)
    |> Poison.decode!()
    |> Enum.map(fn e ->
      %PermissionGroup{
        permission_id: e["permission_id"],
        group_id: e["group_id"]
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
