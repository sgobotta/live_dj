defmodule Livedj.Sessions.Chat.Commands.ParserTest do
  use ExUnit.Case, async: true

  alias Livedj.Sessions.Chat.Commands.Parser

  describe "parse/1 — plain text" do
    test "returns {:text, content} for plain input" do
      assert Parser.parse("hello world") == {:ok, {:text, "hello world"}}
    end

    test "returns {:text, content} for empty string" do
      assert Parser.parse("") == {:ok, {:text, ""}}
    end
  end

  describe "parse/1 — /me" do
    test "parses /me emote" do
      assert Parser.parse("/me dances wildly") == {:ok, {:me, "dances wildly"}}
    end

    test "handles /me with no trailing content" do
      assert Parser.parse("/me") == {:ok, {:me, ""}}
    end
  end

  describe "parse/1 — /skip" do
    test "parses /skip" do
      assert Parser.parse("/skip") == {:ok, {:skip, nil}}
    end
  end

  describe "parse/1 — /queue" do
    test "parses /queue with a url" do
      assert Parser.parse("/queue https://youtu.be/abc123") ==
               {:ok, {:queue, "https://youtu.be/abc123"}}
    end
  end

  describe "parse/1 — /name" do
    test "parses /name with a new name" do
      assert Parser.parse("/name Santiago") == {:ok, {:name, "Santiago"}}
    end
  end

  describe "parse/1 — /msg" do
    test "parses /msg with room_id and content" do
      assert Parser.parse("/msg room-abc hello there") ==
               {:ok, {:msg, "room-abc", "hello there"}}
    end
  end

  describe "parse/1 — unknown command" do
    test "returns error for unknown slash command" do
      assert Parser.parse("/foobar") == {:error, {:unknown_command, "foobar"}}
    end

    test "returns error for /unknown with args" do
      assert Parser.parse("/unknown arg1 arg2") ==
               {:error, {:unknown_command, "unknown"}}
    end
  end
end
