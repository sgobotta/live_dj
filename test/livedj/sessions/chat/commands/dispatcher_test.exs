defmodule Livedj.Sessions.Chat.Commands.DispatcherTest do
  use Livedj.DataCase
  use ExUnit.Case

  alias Livedj.Sessions
  alias Livedj.Sessions.Chat.Commands.Dispatcher
  alias Livedj.Sessions.Chat.Message

  import Livedj.MediaFixtures
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

  describe "dispatch/4 — /queue" do
    test "queueing a video broadcasts an :announcement message", %{
      room_id: room_id,
      user_id: user_id
    } do
      {:ok, :joined} = Sessions.join_playlist(room_id)
      %{external_id: external_id, title: title} = video_fixture()

      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      assert :ok =
               Dispatcher.dispatch(
                 room_id,
                 user_id,
                 "Alice",
                 "/queue #{external_id}"
               )

      assert_receive {:message_sent, ^room_id,
                      %Message{
                        type: :announcement,
                        display_name: "Alice",
                        content: content
                      }}

      assert content =~ title
    end

    test "returns a local :system message when the video cannot be queued",
         %{room_id: room_id, user_id: user_id} do
      {:ok, :joined} = Sessions.join_playlist(room_id)
      %{external_id: external_id} = video_fixture()
      {:ok, {:added, _media}} = Sessions.add_media(room_id, external_id)

      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      assert {:local, %Message{type: :system, content: content}} =
               Dispatcher.dispatch(
                 room_id,
                 user_id,
                 "Alice",
                 "/queue #{external_id}"
               )

      assert is_binary(content)
      refute_receive {:message_sent, _, _}
    end
  end

  describe "dispatch/4 — unknown command" do
    test "returns a local :system message instead of broadcasting", %{
      room_id: room_id,
      user_id: user_id
    } do
      :ok = Phoenix.PubSub.subscribe(Livedj.PubSub, "chat:#{room_id}")

      assert {:local,
              %Message{type: :system, content: "Unknown command: /bogus"}} =
               Dispatcher.dispatch(room_id, user_id, "Alice", "/bogus")

      refute_receive {:message_sent, _, _}
    end
  end
end
