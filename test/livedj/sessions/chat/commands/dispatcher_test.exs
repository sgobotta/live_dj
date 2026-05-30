defmodule Livedj.Sessions.Chat.Commands.DispatcherTest do
  use Livedj.DataCase
  use ExUnit.Case

  alias Livedj.Sessions
  alias Livedj.Sessions.Chat.Message
  alias Livedj.Sessions.Chat.Commands.Dispatcher

  import Livedj.SessionsFixtures

  setup do
    %{id: room_id} = room_fixture()
    {:ok, _messages} = Sessions.join_chat(room_id)
    user_id = Ecto.UUID.generate()

    %{room_id: room_id, user_id: user_id}
  end

  describe "dispatch/4 — :text" do
    test "sends a :text message to the ChatServer", %{
      room_id: room_id,
      user_id: user_id
    } do
      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      :ok = Dispatcher.dispatch(room_id, user_id, "Alice", "hello world")

      assert_receive {:message_sent, ^room_id,
                      %Message{type: :text, content: "hello world"}}
    end
  end

  describe "dispatch/4 — /me" do
    test "sends a :reaction message to the ChatServer", %{
      room_id: room_id,
      user_id: user_id
    } do
      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      :ok = Dispatcher.dispatch(room_id, user_id, "Alice", "/me dances")

      assert_receive {:message_sent, ^room_id,
                      %Message{type: :reaction, content: "dances"}}
    end
  end

  describe "dispatch/4 — unknown command" do
    test "sends a :system message with error text", %{
      room_id: room_id,
      user_id: user_id
    } do
      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      :ok = Dispatcher.dispatch(room_id, user_id, "Alice", "/bogus")

      assert_receive {:message_sent, ^room_id,
                      %Message{
                        type: :system,
                        content: "Unknown command: /bogus"
                      }}
    end
  end
end
