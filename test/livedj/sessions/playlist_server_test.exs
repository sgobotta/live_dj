defmodule Livedj.Sessions.PlaylistServerTest do
  @moduledoc """
  Playlist Server test module
  """
  use Livedj.DataCase
  use ExUnit.Case

  alias Livedj.Sessions.{PlaylistServer, Room}

  import Livedj.SessionsFixtures

  describe "client interface" do
    setup do
      %Room{id: room_id} = room_fixture()
      on_start = fn _state -> :ok end
      args = [on_start: on_start, id: room_id]
      pid = start_supervised!({PlaylistServer, args})

      %{pid: pid, id: room_id}
    end

    test "lock/2 sets a locked status and returns {:ok, :locked}", %{pid: pid} do
      response = do_lock(pid)
      assert response == {:ok, :locked}
    end

    test "unlock/2 sets an unlocked status and returns :ok", %{pid: pid} do
      response = do_unlock(pid)
      assert response == :ok
    end

    test "join/2 successfully adds a member and returns {:ok, :joined}", %{
      pid: pid
    } do
      response = do_join(pid)

      assert response == {:ok, :joined}
    end

    defp do_lock(pid), do: PlaylistServer.lock(pid)

    defp do_unlock(pid), do: PlaylistServer.unlock(pid)

    defp do_join(pid), do: PlaylistServer.join(pid)
  end

  describe "server implementation" do
    setup do
      on_start = fn _state -> :ok end
      %Room{id: room_id} = room_fixture()
      args = [on_start: on_start, id: room_id]
      state = PlaylistServer.initial_state(args)

      %{state: state}
    end

    test "handle_call/3 :lock replies with a locked status", %{state: state} do
      response = PlaylistServer.handle_call(:lock, self(), state)

      {:reply, {:ok, :locked}, ^state} = response
    end

    test "handle_call/3 :join replies with a locked status", %{state: state} do
      pid = self()
      response = PlaylistServer.handle_call(:join, {pid, nil}, state)

      {:reply, {:ok, :joined}, state} = response

      assert Enum.member?(Map.values(state.members), pid)
    end

    test "handle_cast/2 :unlock unlocks a playlist and does not reply",
         %{state: state} do
      response = PlaylistServer.handle_cast(:unlock, state)

      {:noreply, ^state} = response
    end
  end
end
