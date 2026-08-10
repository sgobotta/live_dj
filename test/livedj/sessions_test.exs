defmodule Livedj.SessionsTest do
  @moduledoc false
  use Livedj.DataCase

  alias Livedj.Sessions
  alias Livedj.Sessions.Exceptions.SessionRoomError

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
      assert {:ok, _} = Ecto.UUID.cast(room.slug)
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sessions.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      update_attrs = %{name: "some updated name", slug: "some updated slug"}

      assert {:ok, %Room{} = room} = Sessions.update_room(room, update_attrs)
      assert room.name == "some updated name"
      assert {:ok, _} = Ecto.UUID.cast(room.slug)
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
      assert_raise SessionRoomError, fn -> Sessions.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Sessions.change_room(room)
    end
  end

  describe "room password protection" do
    import Livedj.SessionsFixtures

    test "room_protected?/1 reflects presence of a password" do
      assert Sessions.room_protected?(room_fixture(%{password: "secret1"}))
      refute Sessions.room_protected?(room_fixture())
    end

    test "verify_room_password/2 accepts the correct password" do
      room = room_fixture(%{password: "secret1"})
      assert Sessions.verify_room_password(room, "secret1")
    end

    test "verify_room_password/2 rejects an incorrect password" do
      room = room_fixture(%{password: "secret1"})
      refute Sessions.verify_room_password(room, "wrong")
    end

    test "verify_room_password/2 returns false for a public room" do
      refute Sessions.verify_room_password(room_fixture(), "anything")
    end

    test "verify_room_password/2 returns false for blank input on a protected room" do
      room = room_fixture(%{password: "secret1"})
      refute Sessions.verify_room_password(room, "")
      refute Sessions.verify_room_password(room, nil)
    end

    test "authorization_fingerprint/1 is nil for public rooms, stable for protected" do
      assert Sessions.authorization_fingerprint(room_fixture()) == nil

      room = room_fixture(%{password: "secret1"})
      fp = Sessions.authorization_fingerprint(room)
      assert is_binary(fp)
      assert Sessions.authorization_fingerprint(room) == fp
    end

    test "authorization_fingerprint/1 changes when the password changes" do
      room = room_fixture(%{password: "secret1"})
      fp1 = Sessions.authorization_fingerprint(room)

      {:ok, updated} =
        Sessions.update_room_password(room, %{"password" => "secret2"})

      fp2 = Sessions.authorization_fingerprint(updated)

      assert is_binary(fp1) and is_binary(fp2)
      refute fp1 == fp2
    end

    test "update_room_password/2 sets then clears protection" do
      room = room_fixture()

      {:ok, protected} =
        Sessions.update_room_password(room, %{"password" => "secret1"})

      assert Sessions.room_protected?(protected)
      fp = Sessions.authorization_fingerprint(protected)

      {:ok, cleared} =
        Sessions.update_room_password(protected, %{"password" => ""})

      refute Sessions.room_protected?(cleared)
      refute Sessions.authorization_fingerprint(cleared) == fp
    end
  end
end
