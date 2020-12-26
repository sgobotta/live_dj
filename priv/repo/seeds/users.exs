Code.require_file("utils.exs", __DIR__)

alias LiveDj.Repo
alias LiveDj.Accounts.User
alias LiveDj.Seeds.Utils

json_file = "#{__DIR__}/users.json"

try do
  with {:ok, body} <- File.read(json_file),
    {:ok, users} <- Jason.decode(body, keys: :atoms) do

    date_keys = [:confirmed_at, :inserted_at, :updated_at]
    users = Enum.map(users, fn user ->
      Map.merge(
        user,
        Utils.dates_to_naive_datetime(user, date_keys)
      )
    end)
    {count, _} = Repo.insert_all(User, users)
    IO.inspect("Inserted #{count} users.")
  end

rescue
  Postgrex.Error ->
    IO.inspect("User seeds were already loaded in the database. Skipping execution.")
  error ->
    IO.inspect("Unexpected error while loading User seeds.")
    IO.inspect(error)
end
