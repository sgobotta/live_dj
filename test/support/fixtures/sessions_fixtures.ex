defmodule Livedj.SessionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Livedj.Sessions` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        name: "some name",
        slug: "some slug"
      })
      |> Livedj.Sessions.create_room()

    room
  end
end
