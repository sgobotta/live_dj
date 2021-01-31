Code.require_file("utils.exs", __DIR__)

require Logger

alias LiveDj.Repo
alias LiveDj.Organizer.Room
alias LiveDj.Seeds.Utils

json_file = "#{__DIR__}/rooms.json"

try do
  with {:ok, body} <- File.read(json_file),
    {:ok, rooms} <- Jason.decode(body, keys: :atoms) do

    date_keys = [:inserted_at, :updated_at]
    rooms = Enum.map(rooms, fn room ->
      Map.merge(
        room,
        Utils.dates_to_naive_datetime(room, date_keys)
      )
    end)
    {count, _} = Repo.insert_all(Room, rooms)
    count
  end
rescue
  Postgrex.Error ->
    Logger.info("Room seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.error("❌ Unexpected error while loading Room seeds.")
    Logger.error(error)
    raise error
else
  count ->
    Logger.info("✅ Inserted #{count} rooms.")
end
