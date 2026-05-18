defmodule Livedj.Sessions.PlaybackClockTest do
  use Livedj.DataCase

  alias Livedj.Sessions.{PlaybackClock, PlaybackPosition, Player, Room}

  import Livedj.SessionsFixtures

  describe "play/1 and pause/2" do
    setup do
      %Room{id: room_id} = room_fixture()
      {:ok, _} = Player.maybe_initialise_player(room_id)
      clock_pid = start_supervised!({PlaybackClock, [id: room_id]})

      %{room_id: room_id, clock_pid: clock_pid}
    end

    test "play sets played_at and sync advances position", %{
      clock_pid: clock_pid
    } do
      {:ok, %Player{state: :playing, played_at: played_at}} =
        PlaybackClock.play(clock_pid)

      assert %DateTime{} = played_at

      Process.sleep(1100)

      {:ok, synced} = PlaybackClock.sync_player(clock_pid)
      assert synced.current_time >= 1

      {:ok, %Player{state: :paused, played_at: nil, current_time: at}} =
        PlaybackClock.pause(clock_pid, at: synced.current_time)

      assert at == synced.current_time

      assert PlaybackPosition.sync(%{synced | state: :paused, played_at: nil}).current_time ==
               at
    end

    test "pause clears played_at in redis", %{
      room_id: room_id,
      clock_pid: clock_pid
    } do
      {:ok, _} = PlaybackClock.play(clock_pid)
      {:ok, _} = PlaybackClock.pause(clock_pid, at: 5)

      {:ok, %Player{played_at: nil, state: :paused, current_time: 5}} =
        Player.get(room_id)
    end
  end
end
