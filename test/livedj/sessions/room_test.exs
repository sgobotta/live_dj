defmodule Livedj.Sessions.RoomTest do
  @moduledoc false
  use Livedj.DataCase, async: true

  alias Livedj.Sessions.Room

  describe "changeset/2 password" do
    test "hashes a valid password into password_hash" do
      changeset =
        Room.changeset(%Room{}, %{"name" => "n", "password" => "secret"})

      assert changeset.valid?
      hash = Ecto.Changeset.get_change(changeset, :password_hash)
      assert is_binary(hash)
      assert Bcrypt.verify_pass("secret", hash)
      refute Ecto.Changeset.get_change(changeset, :password)
    end

    test "leaves password_hash nil when password is blank (public room)" do
      changeset = Room.changeset(%Room{}, %{"name" => "n", "password" => ""})

      assert changeset.valid?
      refute Ecto.Changeset.get_change(changeset, :password_hash)
    end

    test "leaves password_hash nil when password is absent (public room)" do
      changeset = Room.changeset(%Room{}, %{"name" => "n"})

      assert changeset.valid?
      refute Ecto.Changeset.get_change(changeset, :password_hash)
    end

    test "rejects a too-short password" do
      changeset = Room.changeset(%Room{}, %{"name" => "n", "password" => "ab"})

      refute changeset.valid?
      assert %{password: [_]} = errors_on(changeset)
    end

    test "accepts a 32-character password" do
      changeset =
        Room.changeset(%Room{}, %{
          "name" => "n",
          "password" => String.duplicate("a", 32)
        })

      assert changeset.valid?
    end

    test "rejects a password longer than 32 characters" do
      changeset =
        Room.changeset(%Room{}, %{
          "name" => "n",
          "password" => String.duplicate("a", 33)
        })

      refute changeset.valid?
      assert %{password: [_]} = errors_on(changeset)
    end
  end

  describe "password_changeset/2" do
    test "sets a hashed password" do
      changeset = Room.password_changeset(%Room{}, %{"password" => "hunter2"})

      assert changeset.valid?
      hash = Ecto.Changeset.get_change(changeset, :password_hash)
      assert Bcrypt.verify_pass("hunter2", hash)
    end

    test "clears the password when blank" do
      room = %Room{password_hash: "existing-hash"}
      changeset = Room.password_changeset(room, %{"password" => ""})

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :password_hash) == nil
    end

    test "rejects a too-short password" do
      changeset = Room.password_changeset(%Room{}, %{"password" => "ab"})
      refute changeset.valid?
    end
  end
end
