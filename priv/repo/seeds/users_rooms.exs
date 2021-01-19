alias LiveDj.Organizer

try do
  users_rooms = [
  # {room_id, user_id, is_owner}
    {1,  1, true},
    {1,  2, false},
    {1,  3, false},
    {1,  4, false},
    {1,  5, false},
    {1,  6, false},

    {2,  1, true},
    {2,  2, false},
    {2,  3, false},
    {2,  4, false},
    {2,  5, false},
    {2,  6, false},

    {3,  1, true},
    {3,  2, false},
    {3,  3, false},
    {3,  4, false},
    {3,  5, false},
    {3,  6, false},

    {4,  1, true},
    {5,  1, true},
    {6,  6, true},
    {7,  1, true},
    {8,  1, true},
    {9,  1, true},
    {10, 1, true},
    {11, 2, true},
    {12, 6, true},
    {13, 5, true},
    {14, 1, true},
    {15, 3, true},
  ]
  |> Enum.map(
      fn {room_id, user_id, is_owner} ->
        {:ok, _} = Organizer.create_user_room(%{
          is_owner: is_owner,
          room_id: room_id,
          user_id: user_id
        })
      end
    )

  IO.inspect("Inserted #{length(users_rooms)} user/room relationships.")

rescue
  Postgrex.Error ->
    IO.inspect("UserRoom seeds were already loaded in the database. Skipping execution.")
  error ->
    IO.inspect("Unexpected error while loading UserRoom seeds.")
    IO.inspect(error)
end
