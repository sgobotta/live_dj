defmodule Livedj.SessionsTest do
  @moduledoc false
  use Livedj.DataCase

  alias Livedj.Sessions
  alias Livedj.Sessions.Channels
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

    test "update_room_password/2 broadcasts a password change to the room topic" do
      room = room_fixture()
      :ok = Channels.subscribe_room_topic(room.id)

      {:ok, _room} =
        Sessions.update_room_password(room, %{"password" => "secret1"})

      assert_receive {:password_changed, room_id}
      assert room_id == room.id
    end

    test "update_room_password/2 raises when the password key is absent" do
      protected = room_fixture(%{password: "secret1"})

      assert_raise ArgumentError, fn ->
        Sessions.update_room_password(protected, %{})
      end

      # the password must be left untouched, not silently cleared
      assert Sessions.room_protected?(Sessions.get_room!(protected.id))
    end
  end

  describe "room name" do
    import Livedj.SessionsFixtures

    test "update_room_name/2 renames the room" do
      room = room_fixture()

      {:ok, renamed} = Sessions.update_room_name(room, %{"name" => "New Name"})

      assert renamed.name == "New Name"
    end

    test "update_room_name/2 broadcasts a name change to the room topic" do
      room = room_fixture()
      :ok = Channels.subscribe_room_topic(room.id)

      {:ok, _room} = Sessions.update_room_name(room, %{"name" => "New Name"})

      assert_receive {:room_name_changed, room_id}
      assert room_id == room.id
    end

    test "update_room_name/2 returns an error changeset for a blank name" do
      room = room_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Sessions.update_room_name(room, %{"name" => ""})

      assert Sessions.get_room!(room.id).name == room.name
    end

    test "update_room_name/2 raises when the name key is absent" do
      room = room_fixture()

      assert_raise ArgumentError, fn ->
        Sessions.update_room_name(room, %{})
      end

      assert Sessions.get_room!(room.id).name == room.name
    end
  end

  describe "play_track/4" do
    import Livedj.SessionsFixtures

    test "returns :error and sends no chat message for an unknown track" do
      %{id: room_id} = room_fixture()
      {:ok, _messages} = Sessions.join_chat(room_id)
      user_id = Ecto.UUID.generate()

      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      assert :error =
               Sessions.play_track(room_id, "unknown_id", user_id, "Alice")

      refute_receive {:message_sent, _room_id, _message}
    end
  end

  describe "playlist_has_media?/1" do
    import Livedj.MediaFixtures
    import Livedj.SessionsFixtures

    alias Livedj.Sessions.Playlist

    test "returns false for a room with an empty playlist" do
      %{id: room_id} = room_fixture()

      refute Sessions.playlist_has_media?(room_id)
    end

    test "returns true once a track has been queued" do
      %{id: room_id} = room_fixture()
      %{external_id: external_id} = video_fixture()

      :ok = Playlist.add(room_id, external_id)

      assert Sessions.playlist_has_media?(room_id)
    end
  end

  describe "next_track/1" do
    import Livedj.MediaFixtures
    import Livedj.SessionsFixtures

    alias Livedj.Sessions.Player
    alias Livedj.Sessions.Playlist

    test "clears the player and re-broadcasts load_media when the playlist has no next track" do
      %{id: room_id} = room_fixture()
      video = video_fixture()

      :ok = Playlist.add(room_id, video.external_id)

      {:ok, %Player{media_id: media_id}} =
        Player.load_media(room_id, video,
          seek_to: 0,
          autoplay: true,
          duration: 180
        )

      assert media_id == video.external_id

      :ok = Channels.subscribe_player_topic(room_id)

      assert :ok = Sessions.next_track(room_id)

      assert_receive {:player_load_media, ^room_id,
                      %Player{
                        media_id: "",
                        state: :idle,
                        media_thumbnail_url: "",
                        title: "",
                        channel: ""
                      }}

      assert {:ok,
              %Player{
                media_id: "",
                state: :idle,
                media_thumbnail_url: "",
                title: "",
                channel: ""
              }} = Sessions.get_player(room_id)
    end
  end
end
