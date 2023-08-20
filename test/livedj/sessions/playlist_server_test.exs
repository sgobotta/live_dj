defmodule Livedj.Sessions.PlaylistServerTest do
  @moduledoc """
  Playlist Server test module
  """
  use Livedj.DataCase
  use ExUnit.Case

  alias Livedj.Sessions.{Channels, PlaylistServer, Room}

  import Livedj.SessionsFixtures
  import Livedj.RuntimeHelpers

  @subject PlaylistServer

  describe "client interface" do
    setup do
      %Room{id: room_id} = room_fixture()
      on_start = fn _state -> :ok end
      args = [on_start: on_start, id: room_id]
      pid = start_supervised!({@subject, args})

      %{pid: pid, id: room_id}
    end

    test "add/2 returns {:ok, :added}", %{pid: pid} do
      response = do_add(pid, "some element")
      assert response == {:ok, :added}
    end

    test "remove/2 returns {:ok, :removed}", %{pid: pid} do
      response = do_remove(pid, "some element")
      assert response == {:ok, :removed}
    end

    test "lock/2 sets a locked status and returns {:ok, :locked}", %{pid: pid} do
      response = do_lock(pid)
      assert response == {:ok, :locked}
    end

    test "unlock/2 sets an unlocked status and returns :ok", %{pid: pid} do
      response = do_unlock(pid, self())
      assert response == :ok
    end

    test "join/2 successfully adds a member and returns {:ok, :joined}", %{
      pid: pid
    } do
      response = do_join(pid)

      assert response == {:ok, :joined}
    end

    defp do_lock(pid), do: @subject.lock(pid)

    defp do_add(pid, arg), do: @subject.add(pid, arg)

    defp do_remove(pid, arg), do: @subject.remove(pid, arg)

    defp do_unlock(pid, from), do: @subject.unlock(pid, from)

    defp do_join(pid), do: @subject.join(pid)
  end

  describe "server implementation" do
    setup do
      on_start = fn _state -> :ok end
      %Room{id: room_id} = room_fixture()
      args = [on_start: on_start, id: room_id]
      state = @subject.initial_state(args)

      %{state: state}
    end

    test "handle_call/3 :lock replies with a locked status", %{state: state} do
      pid = self()

      {:reply, {:ok, :locked}, %{drag_state: {:locked, ^pid, _timeout_ref}},
       {:continue, {:locked, ^pid}}} =
        do_handle_lock({pid, Process.monitor(pid)}, state)
    end

    test "handle_call/3 :join replies with a joined status", %{state: state} do
      pid = self()
      response = do_handle_join({pid, Process.monitor(pid)}, state)

      {:reply, {:ok, :joined}, state} = response

      assert Enum.member?(Map.values(state.members), pid)
    end

    test "handle_call/3 {:add, args} replies with an added status", %{
      state: state
    } do
      pid = self()
      response = do_handle_add("some element", pid, state)

      {:reply, {:ok, :added}, ^state} = response
    end

    test "handle_call/3 {:remove, args} replies with a removed status", %{
      state: state
    } do
      pid = self()
      response = do_handle_remove("some element", pid, state)

      {:reply, {:ok, :removed}, ^state} = response
    end

    test "handle_cast/2 :unlock unlocks drag playlist and does not reply",
         %{state: state} do
      pid = self()

      response =
        do_handle_unlock(pid, %{state | drag_state: {:locked, pid, make_ref()}})

      {:noreply, ^state, {:continue, {:unlocked, ^pid}}} = response
    end

    test "handle_cast/2 :unlock does not continue when the state is :free",
         %{state: state} do
      pid = self()
      response = do_handle_unlock(pid, state)
      {:noreply, ^state} = response
    end

    test "handle_continue/2 {:locked, pid} notifies the locked state", %{
      state: state
    } do
      [{client_pid, _client_user}] = spawn_client(1)

      :ok = Channels.subscribe_playlist_topic(state.id)

      {:noreply, _state} = do_handle_locked(client_pid, state)

      message_name = Channels.dragging_locked_event()
      assert_receive(^message_name)
    end

    test "handle_continue/2 {:unlocked, pid} notifies the unlocked state", %{
      state: state
    } do
      [{client_pid, _client_user}] = spawn_client(1)

      :ok = Channels.subscribe_playlist_topic(state.id)

      {:noreply, _state} = do_handle_unlocked(client_pid, state)

      message_name = Channels.dragging_unlocked_event()
      assert_receive(^message_name)
    end

    test "handle_info/2 {:lock_timeout, from} unlocks drag and does not reply",
         %{state: state} do
      pid = self()

      response =
        do_handle_lock_timeout(pid, %{
          state
          | drag_state: {:locked, pid, make_ref()}
        })

      assert {:noreply, %{drag_state: :free}, {:continue, {:unlocked, ^pid}}} =
               response
    end

    test "handle_info/2 {:DOWN, ref, :process, pid, reason} is called once and returns a state without members",
         %{state: state} do
      # Setup
      clients = spawn_client(1)

      state =
        Enum.reduce(clients, state, fn {client_pid, _client_user}, acc ->
          {:reply, {:ok, :joined}, state} =
            do_handle_join({client_pid, Process.monitor(client_pid)}, acc)

          state
        end)

      assert length(Map.values(state.members)) == length(clients)

      # Exercise
      state =
        Enum.reduce(state.members, state, fn {ref, pid}, acc ->
          {:noreply, state} =
            @subject.handle_info(
              {:DOWN, ref, :process, pid, :normal},
              acc
            )

          state
        end)

      # Verify
      assert Enum.empty?(Map.values(state.members))
    end

    defp do_handle_lock(from, state),
      do: @subject.handle_call(:lock, from, state)

    defp do_handle_unlock(from, state),
      do: @subject.handle_cast({:unlock, from}, state)

    defp do_handle_join(from, state),
      do: @subject.handle_call(:join, from, state)

    defp do_handle_add(arg, from, state),
      do: @subject.handle_call({:add, arg}, from, state)

    defp do_handle_remove(arg, from, state),
      do: @subject.handle_call({:remove, arg}, from, state)

    defp do_handle_locked(arg, state),
      do: @subject.handle_continue({:locked, arg}, state)

    defp do_handle_unlocked(arg, state),
      do: @subject.handle_continue({:unlocked, arg}, state)

    defp do_handle_lock_timeout(from, state),
      do: @subject.handle_info({:lock_timeout, from}, state)
  end
end
