defmodule LiveDj.StatsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Stats` context.
  """

  def badge_fixture(attrs \\ %{}) do
    {:ok, badge} =
      attrs
      |> Enum.into(%{
        description: "Rightfully registered.",
        icon: "1-registered-dj",
        inserted_at: "2020-01-07 16:20:00",
        name: "Registered Dj",
        reference_name: "users-confirmed_via_link"
      })
      |> LiveDj.Stats.create_badge()
      badge
  end

end
