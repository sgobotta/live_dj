defmodule Livedj.Sessions.PlaybackPositionTest do
  use ExUnit.Case

  alias Livedj.Sessions.{PlaybackPosition, Player}

  describe "sync/1" do
    test "returns stored current_time when paused" do
      player = %Player{state: :paused, current_time: 42, played_at: nil}

      assert %Player{current_time: 42} = PlaybackPosition.sync(player)
    end

    test "advances current_time while playing from played_at" do
      played_at = DateTime.utc_now() |> DateTime.add(-10, :second)

      player = %Player{
        state: :playing,
        current_time: 30,
        played_at: played_at
      }

      synced = PlaybackPosition.sync(player)
      assert synced.current_time >= 39
      assert synced.current_time <= 41
    end

    test "coerces string current_time from redis" do
      player = %Player{state: :paused, current_time: "15", played_at: nil}

      assert %Player{current_time: 15} = PlaybackPosition.sync(player)
    end
  end

  describe "track_ended?/2" do
    test "is true when playing position reached duration" do
      played_at = DateTime.utc_now() |> DateTime.add(-100, :second)

      player = %Player{
        state: :playing,
        current_time: 0,
        played_at: played_at,
        duration: 90
      }

      assert PlaybackPosition.track_ended?(player)
    end

    test "is false without duration" do
      player = %Player{state: :playing, current_time: 999, duration: nil}

      refute PlaybackPosition.track_ended?(player)
    end

    test "is false when paused" do
      player = %Player{state: :paused, current_time: 100, duration: 10}

      refute PlaybackPosition.track_ended?(player)
    end

    test "uses millisecond precision instead of a whole-second bias" do
      # duration 90, default epsilon 0.25 -> triggers at position >= 89.75
      just_before = DateTime.utc_now() |> DateTime.add(-89_500, :millisecond)
      just_after = DateTime.utc_now() |> DateTime.add(-89_800, :millisecond)

      refute PlaybackPosition.track_ended?(%Player{
               state: :playing,
               current_time: 0,
               played_at: just_before,
               duration: 90
             })

      assert PlaybackPosition.track_ended?(%Player{
               state: :playing,
               current_time: 0,
               played_at: just_after,
               duration: 90
             })
    end
  end
end
