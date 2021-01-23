alias LiveDj.Repo
alias LiveDj.Accounts.Permission

require Logger

schema_upper = "Permission"
schema_plural = "permissions"
env_var = "LIVEDJ_PERMISSIONS"

try do
  System.get_env(env_var)
    |> Poison.decode!()
    |> Enum.map(fn e ->
      %Permission{
        id: e["id"],
        codename: e["codename"],
        name: e["name"]
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
