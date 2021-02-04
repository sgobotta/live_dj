alias LiveDj.Organizer

require Logger

try do
  # Assumes Rooms, Users and Groups were created
  # {room_id, user_id, is_owner, group_id}
  [
    {1,  1, true,  3},
    {1,  2, false, 4},
    {1,  3, false, 4},
    {1,  4, false, 4},
    {1,  5, false, 4},
    {1,  6, false, 4},

    {2,  1, true,  3},
    {2,  2, false, 4},
    {2,  3, false, 4},
    {2,  4, false, 4},
    {2,  5, false, 4},
    {2,  6, false, 4},

    {3,  1, true,  3},
    {3,  2, false, 4},
    {3,  3, false, 4},
    {3,  4, false, 4},
    {3,  5, false, 4},
    {3,  6, false, 4},

    {4,  1, true, 3},
    {5,  1, true, 3},
    {6,  6, true, 3},
    {7,  1, true, 3},
    {8,  1, true, 3},
    {9,  1, true, 3},
    {10, 1, true, 3},
    {11, 2, true, 3},
  ]
  |> Enum.map(
      fn {room_id, user_id, is_owner, group_id} ->
        {:ok, _} = Organizer.create_user_room(%{
          is_owner: is_owner,
          room_id: room_id,
          user_id: user_id,
          group_id: group_id,
        })
      end
    )
rescue
  Postgrex.Error ->
    Logger.info("UserRoom seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.error("❌ Unexpected error while loading UserRoom seeds.")
    Logger.error(error)
    raise error
else
  elements ->
    Logger.info("✅ Inserted #{length(elements)} user/room relationships.")
end
