defmodule Livedj.Sessions.PlayerServerTest do
  use Livedj.DataCase

  alias Livedj.Sessions.{PlayerServer, Room}

  import Livedj.SessionsFixtures

  @subject PlayerServer

  describe "controller and report_track_ended/2" do
    setup do
      %Room{id: room_id} = room_fixture()
      on_start = fn _state -> :ok end
      pid = start_supervised!({@subject, [on_start: on_start, id: room_id]})

      %{pid: pid, room_id: room_id}
    end

    test "first joiner becomes controller and may report track ended", %{
      pid: pid
    } do
      parent = self()

      controller =
        spawn(fn ->
          {:ok, :joined} =
            @subject.join(pid, on_joined: {fn -> {:ok, %{}} end, []})

          send(parent, {:ready, self()})

          receive do
            {:report, reply_to} ->
              result =
                @subject.report_track_ended(pid,
                  on_track_ended:
                    {fn ->
                       send(reply_to, :track_ended_cb)
                       :ok
                     end, []}
                )

              send(reply_to, {:report_result, result})
          end
        end)

      assert_receive {:ready, ^controller}

      send(controller, {:report, self()})
      assert_receive :track_ended_cb
      assert_receive {:report_result, {:ok, :handled}}
    end

    test "non-controller joiner reports are ignored", %{pid: pid} do
      parent = self()

      controller =
        spawn(fn ->
          {:ok, :joined} =
            @subject.join(pid, on_joined: {fn -> {:ok, %{}} end, []})

          send(parent, :controller_joined)
          Process.sleep(:infinity)
        end)

      assert_receive :controller_joined

      follower =
        spawn(fn ->
          {:ok, :joined} =
            @subject.join(pid, on_joined: {fn -> {:ok, %{}} end, []})

          send(parent, :follower_joined)

          result =
            @subject.report_track_ended(pid,
              on_track_ended: {fn -> send(parent, :should_not_run) end, []}
            )

          send(parent, {:report_result, result})
        end)

      assert_receive :follower_joined
      assert_receive {:report_result, {:ok, :ignored}}
      refute_receive :should_not_run, 50
      Process.exit(follower, :kill)
      Process.exit(controller, :kill)
    end

    test "promotes a new controller when the current controller leaves", %{
      pid: pid
    } do
      parent = self()

      _controller =
        spawn(fn ->
          {:ok, :joined} =
            @subject.join(pid, on_joined: {fn -> {:ok, %{}} end, []})

          send(parent, {:controller, self()})
          Process.sleep(:infinity)
        end)

      assert_receive {:controller, controller_pid}

      _follower =
        spawn(fn ->
          {:ok, :joined} =
            @subject.join(pid, on_joined: {fn -> {:ok, %{}} end, []})

          send(parent, {:follower, self()})

          receive do
            {:report, reply_to} ->
              result =
                @subject.report_track_ended(pid,
                  on_track_ended:
                    {fn ->
                       send(reply_to, :promoted_cb)
                       :ok
                     end, []}
                )

              send(reply_to, {:report_result, result})
          end
        end)

      assert_receive {:follower, follower_pid}

      Process.exit(controller_pid, :kill)
      ref = Process.monitor(controller_pid)
      assert_receive {:DOWN, ^ref, :process, ^controller_pid, _}

      send(follower_pid, {:report, self()})
      assert_receive :promoted_cb
      assert_receive {:report_result, {:ok, :handled}}

      Process.exit(follower_pid, :kill)
    end
  end
end
