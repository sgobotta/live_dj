alias LiveDj.Organizer

require Logger

try do
  # Assumes Rooms, Users and Groups were created
  # {room_id, user_id, is_owner, group_id}
  [
    {1,  1, true,  1},
    {1,  2, false, 2},
    {1,  3, false, 2},
    {1,  4, false, 2},
    {1,  5, false, 2},
    {1,  6, false, 2},

    {2,  1, true,  1},
    {2,  2, false, 2},
    {2,  3, false, 2},
    {2,  4, false, 2},
    {2,  5, false, 2},
    {2,  6, false, 2},

    {3,  1, true,  1},
    {3,  2, false, 2},
    {3,  3, false, 2},
    {3,  4, false, 2},
    {3,  5, false, 2},
    {3,  6, false, 2},

    {4,  1, true, 1},
    {5,  1, true, 1},
    {6,  6, true, 1},
    {7,  1, true, 1},
    {8,  1, true, 1},
    {9,  1, true, 1},
    {10, 1, true, 1},
    {11, 2, true, 1},
    {12, 6, true, 1},
    {13, 5, true, 1},
    {14, 1, true, 1},
    {15, 3, true, 1},
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
