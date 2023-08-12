defmodule Livedj.SessionsTest do
  use Livedj.DataCase

  alias Livedj.Sessions

  describe "rooms" do
    alias Livedj.Sessions.Room

    import Livedj.SessionsFixtures

    @invalid_attrs %{name: nil, slug: nil}

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Sessions.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Sessions.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      valid_attrs = %{name: "some name", slug: "some slug"}

      assert {:ok, %Room{} = room} = Sessions.create_room(valid_attrs)
      assert room.name == "some name"
      assert room.slug == "some slug"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sessions.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      update_attrs = %{name: "some updated name", slug: "some updated slug"}

      assert {:ok, %Room{} = room} = Sessions.update_room(room, update_attrs)
      assert room.name == "some updated name"
      assert room.slug == "some updated slug"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Sessions.update_room(room, @invalid_attrs)

      assert room == Sessions.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Sessions.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Sessions.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Sessions.change_room(room)
    end
  end
end
