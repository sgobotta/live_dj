defmodule LiveDj.OrganizerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Organizer` context.
  """

  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        title: "A title",
        slug: "A slug"
      })
      |> LiveDj.Organizer.create_room()
      room
  end

end
