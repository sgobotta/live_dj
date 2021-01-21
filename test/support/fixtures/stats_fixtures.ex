defmodule LiveDj.StatsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Stats` context.
  """

  def badges_fixture() do
    Code.require_file("../../../priv/repo/seeds/badges.exs", __DIR__)
    LiveDj.Stats.list_badges()
  end

  def badge_fixture(attrs \\ %{}) do
    {:ok, badge} =
      attrs
      |> Enum.into(%{
        description: "A description",
        icon: "an-icon",
        inserted_at: "2020-01-07 16:20:00",
        name: "Name",
        reference_name: "123"
      })
      |> LiveDj.Stats.create_badge()
      badge
  end

end
