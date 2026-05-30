defmodule Livedj.Sessions.ChatServerTest do
  use Livedj.DataCase
  use ExUnit.Case

  alias Livedj.Sessions.{ChatServer, Chat.Message}

  @subject ChatServer

  describe "client interface" do
    setup do
      room_id = Ecto.UUID.generate()
      on_start = fn _state -> :ok end
      pid = start_supervised!({@subject, [on_start: on_start, id: room_id]})

      %{pid: pid, room_id: room_id}
    end

    test "get_messages/1 returns empty list initially", %{pid: pid} do
      assert @subject.get_messages(pid) == []
    end

    test "send_message/5 prepends a message and broadcasts it", %{
      pid: pid,
      room_id: room_id
    } do
      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      :ok = @subject.send_message(pid, "u1", "Alice", :text, "hello")

      assert_receive {:message_sent, ^room_id,
                      %Message{content: "hello", display_name: "Alice"}}

      messages = @subject.get_messages(pid)
      assert length(messages) == 1
      assert hd(messages).content == "hello"
    end

    test "send_message/5 keeps newest first", %{pid: pid, room_id: room_id} do
      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      :ok = @subject.send_message(pid, "u1", "Alice", :text, "first")
      assert_receive {:message_sent, ^room_id, _}

      :ok = @subject.send_message(pid, "u1", "Alice", :text, "second")
      assert_receive {:message_sent, ^room_id, _}

      [newest | _] = @subject.get_messages(pid)
      assert newest.content == "second"
    end

    test "update_display_name/3 updates all messages from that user and broadcasts",
         %{
           pid: pid,
           room_id: room_id
         } do
      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      :ok = @subject.send_message(pid, "u1", "Alice", :text, "hi")
      assert_receive {:message_sent, ^room_id, _}

      :ok = @subject.send_message(pid, "u2", "Bob", :text, "hey")
      assert_receive {:message_sent, ^room_id, _}

      :ok = @subject.update_display_name(pid, "u1", "Alicia")
      assert_receive {:messages_updated, ^room_id, messages}

      alice_messages = Enum.filter(messages, &(&1.user_id == "u1"))
      assert Enum.all?(alice_messages, &(&1.display_name == "Alicia"))

      bob_messages = Enum.filter(messages, &(&1.user_id == "u2"))
      assert Enum.all?(bob_messages, &(&1.display_name == "Bob"))
    end

    test "messages are capped at 200", %{pid: pid, room_id: room_id} do
      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      for i <- 1..201 do
        :ok = @subject.send_message(pid, "u1", "Alice", :text, "msg #{i}")
        assert_receive {:message_sent, ^room_id, _}
      end

      assert length(@subject.get_messages(pid)) == 200
    end
  end
end
