defmodule Livedj.Sessions.Chat.MessageTest do
  use ExUnit.Case, async: true

  alias Livedj.Sessions.Chat.Message

  describe "new/5" do
    test "creates a message with all required fields" do
      msg = Message.new("room-1", "user-1", "Alice", :text, "hello world")

      assert msg.room_id == "room-1"
      assert msg.user_id == "user-1"
      assert msg.display_name == "Alice"
      assert msg.type == :text
      assert msg.content == "hello world"
      assert is_binary(msg.id)
      assert %DateTime{} = msg.inserted_at
    end

    test "each call generates a unique id" do
      msg1 = Message.new("r", "u", "Alice", :text, "a")
      msg2 = Message.new("r", "u", "Alice", :text, "a")

      refute msg1.id == msg2.id
    end

    test "accepts all valid types" do
      for type <- [:text, :system, :reaction, :command_result] do
        msg = Message.new("r", "u", "Alice", type, "content")
        assert msg.type == type
      end
    end
  end
end
