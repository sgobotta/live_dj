alias LiveDj.Repo
alias LiveDj.Accounts.PermissionGroup

require Logger

schema_upper = "PermissionGroup"
schema_plural = "permissions_groups"
env_var = "LIVEDJ_PERMISSIONS_GROUPS"

try do
  System.get_env(env_var)
    |> Poison.decode!()
    |> Enum.map(fn e ->
      %PermissionGroup{
        permission_id: e["permission_id"],
        group_id: e["group_id"]
      }
      |> Repo.insert()
    end)
rescue
  Postgrex.Error ->
    Logger.info("#{schema_upper} seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.error("❌ Unexpected error while loading #{schema_upper} seeds.")
    Logger.error(error)
    raise error
else
  elements ->
    Logger.info("✅ Inserted #{length(elements)} #{schema_plural}.")
end
