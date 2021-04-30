defmodule LiveDj.StatsTest do
  use LiveDj.DataCase

  import LiveDj.AccountsFixtures

  alias LiveDj.Accounts
  alias LiveDj.Stats

  describe "badges" do
    alias LiveDj.Stats.Badge

    @valid_attrs %{
      description: "some description",
      icon: "some icon",
      name: "some name",
      reference_name: "some reference name",
      type: "some type",
      checkpoint: 420
    }
    @update_attrs %{
      description: "some updated description",
      icon: "some updated icon",
      name: "some updated name",
      reference_name: "some updated reference name",
      type: "some updated type",
      checkpoint: 4200
    }
    @invalid_attrs %{
      description: nil,
      icon: nil,
      name: nil,
      reference_name: nil,
      type: nil,
      checkpoint: nil
    }

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
      assert badge.reference_name == "some reference name"
      assert badge.type == "some type"
      assert badge.checkpoint == 420
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
      assert badge.reference_name == "some updated reference name"
      assert badge.type == "some updated type"
      assert badge.checkpoint == 4200
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

    test "assoc_user_badge/2 with valid data creates a user/badge relationship" do
      badge = badge_fixture()
      user = user_fixture()
      assert :ok = Stats.assoc_user_badge(user.id, badge.reference_name)
      preloaded_user = Accounts.get_user!(user.id) |> Repo.preload(:badges)
      assert badge in preloaded_user.badges
      preloaded_badge = Stats.get_badge!(badge.id) |> Repo.preload(:users)
      assert user in preloaded_badge.users
    end
  end

  describe "users_badges" do
    alias LiveDj.Stats.UserBadge
    alias LiveDj.StatsFixtures

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{badge_id: nil, user_id: nil}

    setup do
      user = user_fixture()
      badge = StatsFixtures.badge_fixture()

      %{badge: badge, user: user}
    end

    def user_badge_fixture(attrs \\ %{}) do
      {:ok, user_badge} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Stats.create_user_badge()

      user_badge
    end

    test "list_users_badges/0 returns all users_badges", %{badge: badge, user: user} do
      user_badge = user_badge_fixture(%{badge_id: badge.id, user_id: user.id})
      assert Stats.list_users_badges() == [user_badge]
    end

    test "get_user_badge!/1 returns the user_badge with given id", %{badge: badge, user: user} do
      user_badge = user_badge_fixture(%{badge_id: badge.id, user_id: user.id})
      assert Stats.get_user_badge!(user_badge.id) == user_badge
    end

    test "create_user_badge/1 with valid data creates a user_badge", %{badge: badge, user: user} do
      valid_attrs = Enum.into(@valid_attrs, %{badge_id: badge.id, user_id: user.id})
      assert {:ok, %UserBadge{} = _user_badge} = Stats.create_user_badge(valid_attrs)
    end

    test "create_user_badge/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Stats.create_user_badge(@invalid_attrs)
    end

    test "update_user_badge/2 with valid data updates the user_badge", %{badge: badge, user: user} do
      user_badge = user_badge_fixture(%{user_id: user.id, badge_id: badge.id})

      assert {:ok, %UserBadge{} = _user_badge} =
               Stats.update_user_badge(user_badge, @update_attrs)
    end

    test "update_user_badge/2 with invalid data returns error changeset", %{
      badge: badge,
      user: user
    } do
      user_badge = user_badge_fixture(%{user_id: user.id, badge_id: badge.id})
      assert {:error, %Ecto.Changeset{}} = Stats.update_user_badge(user_badge, @invalid_attrs)
      assert user_badge == Stats.get_user_badge!(user_badge.id)
    end

    test "delete_user_badge/1 deletes the user_badge", %{badge: badge, user: user} do
      user_badge = user_badge_fixture(%{user_id: user.id, badge_id: badge.id})
      assert {:ok, %UserBadge{}} = Stats.delete_user_badge(user_badge)
      assert_raise Ecto.NoResultsError, fn -> Stats.get_user_badge!(user_badge.id) end
    end

    test "change_user_badge/1 returns a user_badge changeset", %{badge: badge, user: user} do
      user_badge = user_badge_fixture(%{user_id: user.id, badge_id: badge.id})
      assert %Ecto.Changeset{} = Stats.change_user_badge(user_badge)
    end
  end
end
