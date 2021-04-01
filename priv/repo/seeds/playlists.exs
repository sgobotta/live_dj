require Logger

alias LiveDj.Collections
alias LiveDj.Organizer

primary_schema_upper = "Room"
primary_schema_plural = "rooms"

secondary_schema_upper = "Playlist"
secondary_schema_plural = "playlists"

try do
  # Assumes Rooms were created
  Organizer.list_rooms()
  |> Enum.map(
      fn room ->
        {:ok, playlist} = Collections.create_playlist()
        {:ok, updated_room} = Organizer.assoc_playlist(room, playlist)
        updated_room
      end
    )
rescue
  Postgrex.Error ->
    Logger.info("#{primary_schema_upper} and #{secondary_schema_upper} seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.error("❌ Unexpected error while loading #{primary_schema_upper} and #{secondary_schema_upper} relation seeds.")
    Logger.error(error)
    raise error
else
  elements ->
    Logger.info("✅ Updated #{length(elements)} #{primary_schema_plural} #{secondary_schema_plural} relationships.")
end
