defmodule LiveDj.OrganizerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Organizer` context.
  """

  alias LiveDj.AccountsFixtures

  def room_fixture(attrs \\ %{}) do
    random_words = Enum.join(Faker.Lorem.words(5), " ")
    {:ok, room} =
      attrs
      |> Enum.into(%{
        title: random_words,
        slug: random_words
      })
      |> LiveDj.Organizer.create_room()
      room
  end

  def user_room_fixture(attrs \\ %{}) do
    user = AccountsFixtures.user_fixture()
    room = room_fixture()
    {:ok, user_room} =
      attrs
      |> Enum.into(%{
        is_owner: true,
        room_id: room.id,
        user_id: user.id,
      })
      |> LiveDj.Organizer.create_user_room()
    %{room: room, user: user, user_room: user_room}
  end
end
