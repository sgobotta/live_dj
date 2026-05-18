defmodule Livedj.Sessions.PlaybackClockTest do
  use Livedj.DataCase

  alias Livedj.Sessions.{PlaybackClock, PlaybackPosition, Player, Room}

  import Livedj.MediaFixtures
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

    test "load_media persists duration in redis", %{room_id: room_id} do
      media = video_fixture()

      assert {:ok, %Player{duration: 120}} =
               Player.load_media(room_id, media, seek_to: 0, duration: 120)
    end

    test "load_media with autoplay clears stale played_at so track is not instantly ended",
         %{
           room_id: room_id
         } do
      _media = video_fixture()
      other = video_fixture()

      {:ok, _} = Player.play(room_id)
      Process.sleep(1100)

      assert {:ok, %Player{state: :playing, played_at: played_at}} =
               Player.load_media(room_id, other,
                 seek_to: 0,
                 duration: 300,
                 autoplay: true
               )

      assert %DateTime{} = played_at
      {:ok, player} = Player.get(room_id)
      refute PlaybackPosition.track_ended?(player)
    end
  end
end
