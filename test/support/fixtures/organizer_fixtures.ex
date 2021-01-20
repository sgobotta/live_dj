defmodule LiveDj.OrganizerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Organizer` context.
  """

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
end
