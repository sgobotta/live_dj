defmodule LiveDj.StatsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveDj.Stats` context.
  """

  alias LiveDj.AccountsFixtures

  def badges_fixture do
    Code.require_file("../../../priv/repo/seeds/badges.exs", __DIR__)
    LiveDj.Stats.list_badges()
  end

  def user_badge_fixture(
        attrs \\ %{},
        user_attrs \\ %{},
        badge_attrs \\ %{}
      ) do
    badge = badge_fixture(Enum.into(badge_attrs, %{reference_name: "Another reference name"}))
    user = AccountsFixtures.user_fixture(user_attrs)

    {:ok, user_badge} =
      attrs
      |> Enum.into(%{
        user_id: user.id,
        badge_id: badge.id
      })
      |> LiveDj.Stats.create_user_badge()

    user_badge
  end

  def badge_fixture(attrs \\ %{}) do
    {:ok, badge} =
      attrs
      |> Enum.into(%{
        description: "A description",
        icon: "an-icon",
        inserted_at: "2020-01-07 16:20:00",
        type: "some type",
        checkpoint: 0,
        name: "Name",
        reference_name: "123"
      })
      |> LiveDj.Stats.create_badge()

    badge
  end
end
