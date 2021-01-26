defmodule LiveDj.OrganizerTest do
  use LiveDj.DataCase

  alias LiveDj.Organizer

  describe "rooms" do
    alias LiveDj.Organizer.Room

    @valid_attrs %{slug: "some slug", title: "some title", management_type: "some management type"}
    @update_attrs %{slug: "some updated slug", title: "some updated title", management_type: "some updated management type"}
    @invalid_attrs %{slug: nil, title: nil}

    def room_fixture(attrs \\ %{}) do
      {:ok, room} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Organizer.create_room()

      room
    end

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Organizer.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Organizer.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      assert {:ok, %Room{} = room} = Organizer.create_room(@valid_attrs)
      assert room.slug == "some-slug"
      assert room.title == "some title"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organizer.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      assert {:ok, %Room{} = room} = Organizer.update_room(room, @update_attrs)
      assert room.slug == "some-updated-slug"
      assert room.title == "some updated title"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Organizer.update_room(room, @invalid_attrs)
      assert room == Organizer.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Organizer.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Organizer.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Organizer.change_room(room)
    end
  end

  describe "users_rooms" do
    alias LiveDj.Organizer.UserRoom
    alias LiveDj.AccountsFixtures
    alias LiveDj.OrganizerFixtures

    @valid_attrs %{is_owner: true}
    @update_attrs %{is_owner: false}
    @invalid_attrs %{is_owner: nil}

    setup do
      user = AccountsFixtures.user_fixture()
      room = OrganizerFixtures.room_fixture()
      group = AccountsFixtures.group_fixture()

      %{room: room, user: user, group: group}
    end

    def user_room_fixture(attrs \\ %{}) do
      {:ok, user_room} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Organizer.create_user_room()

      user_room
    end

    test "list_users_rooms/0 returns all users_rooms", %{user: user, room: room, group: group} do
      user_room = user_room_fixture(%{user_id: user.id, room_id: room.id, group_id: group.id})
      assert Organizer.list_users_rooms() == [user_room]
    end

    test "get_user_room!/1 returns the user_room with given id", %{user: user, room: room, group: group} do
      user_room = user_room_fixture(%{user_id: user.id, room_id: room.id, group_id: group.id})
      assert Organizer.get_user_room!(user_room.id) == user_room
    end

    test "create_user_room/1 with valid data creates a user_room", %{user: user, room: room, group: group} do
      valid_attrs = Enum.into(@valid_attrs, %{user_id: user.id, room_id: room.id, group_id: group.id})
      assert {:ok, %UserRoom{} = user_room} = Organizer.create_user_room(valid_attrs)
      assert user_room.is_owner == true
    end

    test "create_user_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Organizer.create_user_room(@invalid_attrs)
    end

    test "update_user_room/2 with valid data updates the user_room", %{user: user, room: room, group: group} do
      user_room = user_room_fixture(%{user_id: user.id, room_id: room.id, group_id: group.id})
      assert {:ok, %UserRoom{} = user_room} = Organizer.update_user_room(user_room, @update_attrs)
      assert user_room.is_owner == false
    end

    test "update_user_room/2 with invalid data returns error changeset", %{user: user, room: room, group: group} do
      user_room = user_room_fixture(%{user_id: user.id, room_id: room.id, group_id: group.id})
      assert {:error, %Ecto.Changeset{}} = Organizer.update_user_room(user_room, @invalid_attrs)
      assert user_room == Organizer.get_user_room!(user_room.id)
    end

    test "delete_user_room/1 deletes the user_room", %{user: user, room: room, group: group} do
      user_room = user_room_fixture(%{user_id: user.id, room_id: room.id, group_id: group.id})
      assert {:ok, %UserRoom{}} = Organizer.delete_user_room(user_room)
      assert_raise Ecto.NoResultsError, fn -> Organizer.get_user_room!(user_room.id) end
    end

    test "change_user_room/1 returns a user_room changeset", %{user: user, room: room, group: group} do
      user_room = user_room_fixture(%{user_id: user.id, room_id: room.id, group_id: group.id})
      assert %Ecto.Changeset{} = Organizer.change_user_room(user_room)
    end
  end
end
