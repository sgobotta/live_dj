defmodule Livedj.Sessions.VideoDurationTest do
  use ExUnit.Case

  alias Livedj.Sessions.VideoDuration

  describe "parse_iso8601_duration/1" do
    test "parses hours, minutes, and seconds" do
      assert {:ok, 3661} = VideoDuration.parse_iso8601_duration("PT1H1M1S")
    end

    test "parses minutes and seconds" do
      assert {:ok, 93} = VideoDuration.parse_iso8601_duration("PT1M33S")
    end

    test "parses seconds only" do
      assert {:ok, 30} = VideoDuration.parse_iso8601_duration("PT30S")
    end

    test "rejects empty duration" do
      assert :error = VideoDuration.parse_iso8601_duration("PT")
    end

    test "rejects invalid format" do
      assert :error = VideoDuration.parse_iso8601_duration("not-a-duration")
    end
  end
end
