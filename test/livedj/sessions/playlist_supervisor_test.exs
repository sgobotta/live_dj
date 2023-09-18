defmodule Livedj.Sessions.PlaylistSupervisorTest do
  @moduledoc """
  Playlist Supervisor test module
  """
  use Livedj.DataCase
  use ExUnit.Case

  import Livedj.SessionsFixtures

  describe "playlist_supervisor" do
    alias Livedj.Sessions.{PlaylistSupervisor, Room}

    @subject PlaylistSupervisor
    @supervisor_name :playlist_supervisor_test

    setup do
      pid = start_supervised!({PlaylistSupervisor, [name: @supervisor_name]})
      %Room{} = room = room_fixture()

      assert valid_pid?(pid)

      %{pid: pid, room: room}
    end

    test "start_child/2 starts a child with args", %{
      pid: pid,
      room: %Room{id: room_id}
    } do
      {:ok, pid} = do_start_child(pid, id: room_id)

      assert valid_pid?(pid)
    end

    test "list_children/1 returns a list of pids", %{
      pid: pid,
      room: %Room{id: room_id}
    } do
      {:ok, child_pid} = do_start_child(pid, id: room_id)

      assert Enum.member?(do_list_children(pid), child_pid)
    end

    test "get_child/1 returns a pid and state", %{
      pid: pid,
      room: %Room{id: room_id}
    } do
      {:ok, child_pid} = do_start_child(pid, id: room_id)

      {^child_pid, %{id: ^room_id} = state} = do_get_child(room_id)

      valid_pid?(child_pid)
      assert is_map(state)
    end

    test "terminate_child/2 shuts down a pid", %{
      pid: pid,
      room: %Room{id: room_id}
    } do
      {:ok, child_pid} = do_start_child(pid, id: room_id)

      assert valid_pid?(child_pid)

      :ok = do_terminate_child(pid, child_pid)
      refute valid_pid?(child_pid)
    end

    defp do_start_child(pid, args), do: @subject.start_child(pid, args)

    defp do_list_children(pid), do: @subject.list_children(pid)

    defp do_get_child(cart_id),
      do: @subject.get_child(cart_id)

    defp do_terminate_child(pid, child_pid),
      do: @subject.terminate_child(pid, child_pid)
  end

  defp valid_pid?(pid), do: is_pid(pid) and Process.alive?(pid)
end
