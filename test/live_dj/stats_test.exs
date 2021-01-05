defmodule LiveDj.StatsTest do
  use LiveDj.DataCase

  alias LiveDj.Stats

  describe "badges" do
    alias LiveDj.Stats.Badge

    @valid_attrs %{description: "some description", icon: "some icon", name: "some name"}
    @update_attrs %{description: "some updated description", icon: "some updated icon", name: "some updated name"}
    @invalid_attrs %{description: nil, icon: nil, name: nil}

    def badge_fixture(attrs \\ %{}) do
      {:ok, badge} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Stats.create_badge()

      badge
    end

    test "list_badges/0 returns all badges" do
      badge = badge_fixture()
      assert Stats.list_badges() == [badge]
    end

    test "get_badge!/1 returns the badge with given id" do
      badge = badge_fixture()
      assert Stats.get_badge!(badge.id) == badge
    end

    test "create_badge/1 with valid data creates a badge" do
      assert {:ok, %Badge{} = badge} = Stats.create_badge(@valid_attrs)
      assert badge.description == "some description"
      assert badge.icon == "some icon"
      assert badge.name == "some name"
    end

    test "create_badge/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stats.create_badge(@invalid_attrs)
    end

    test "update_badge/2 with valid data updates the badge" do
      badge = badge_fixture()
      assert {:ok, %Badge{} = badge} = Stats.update_badge(badge, @update_attrs)
      assert badge.description == "some updated description"
      assert badge.icon == "some updated icon"
      assert badge.name == "some updated name"
    end

    test "update_badge/2 with invalid data returns error changeset" do
      badge = badge_fixture()
      assert {:error, %Ecto.Changeset{}} = Stats.update_badge(badge, @invalid_attrs)
      assert badge == Stats.get_badge!(badge.id)
    end

    test "delete_badge/1 deletes the badge" do
      badge = badge_fixture()
      assert {:ok, %Badge{}} = Stats.delete_badge(badge)
      assert_raise Ecto.NoResultsError, fn -> Stats.get_badge!(badge.id) end
    end

    test "change_badge/1 returns a badge changeset" do
      badge = badge_fixture()
      assert %Ecto.Changeset{} = Stats.change_badge(badge)
    end
  end
end