defmodule Livedj.Sessions.PlaylistServer do
  @moduledoc """
  The Playlist Server implementation
  """
  use GenServer, restart: :transient

  alias Livedj.Sessions.Channels

  require Logger

  @join_msg :join
  @lock_msg :lock
  @unlock_msg :unlock
  @on_start_cb :on_start
  @locked_cb :locked
  @unlocked_cb :unlocked
  @lock_timeout_cb :lock_timeout

  @lock_timeout :timer.seconds(15)

  @type state :: %{
          :id => binary(),
          :drag_state => :free | {:locked, pid(), reference()},
          :members => map(),
          :lock_timeout => pos_integer()
        }

  @type lock_response ::
          {:ok, :locked} | {:error, :already_locked | :not_an_owner}
  @type unlock_response :: :ok

  # ----------------------------------------------------------------------------
  # Client interface
  #

  @doc """
  Given a keyword of arguments, starts a #{GenServer} process linked to the
  current process.
  """
  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @doc """
  Given a pid, joins the current server
  """
  @spec join(pid()) :: {:ok, :joined}
  def join(pid) do
    GenServer.call(pid, @join_msg)
  end

  @doc """
  Given a pid, locks the playlist drag.
  """
  @spec lock(pid()) :: lock_response()
  def lock(pid) do
    GenServer.call(pid, @lock_msg)
  end

  @doc """
  Given a pid, unlocks the playlist drag.
  """
  @spec unlock(pid(), pid()) :: unlock_response()
  def unlock(pid, from) do
    GenServer.cast(pid, {@unlock_msg, from})
  end

  @doc """
  Given a keyword of args returns a new map that represents the #{__MODULE__}
  state.
  """
  @spec initial_state(keyword()) :: state()
  def initial_state(opts) do
    %{
      id: Keyword.fetch!(opts, :id),
      drag_state: :free,
      members: Map.new(),
      lock_timeout: Keyword.get(opts, :timeout, @lock_timeout)
    }
  end

  # ----------------------------------------------------------------------------
  # Server implementation
  #

  @impl GenServer
  def init(init_args) do
    :ok =
      Logger.info(
        "#{__MODULE__} :: Started process with pid=#{inspect(self())}, args=#{inspect(init_args)}"
      )

    {:ok, initial_state(init_args),
     {:continue, {@on_start_cb, Keyword.fetch!(init_args, :on_start)}}}
  end

  @impl GenServer
  def handle_call(@join_msg, {pid, _ref}, state) do
    ref = Process.monitor(pid)

    Logger.debug(
      "#{__MODULE__} :: User with pid: #{inspect(pid)} just joined the server."
    )

    state = add_member(state, ref, pid)

    {:reply, {:ok, :joined}, state}
  end

  @impl GenServer
  def handle_call(@lock_msg, from, %{drag_state: {:locked, from}} = state) do
    {:reply, {:error, :already_locked}, state}
  end

  def handle_call(@lock_msg, _from, %{drag_state: {:locked, _pid}} = state) do
    {:reply, {:error, :not_an_owner}, state}
  end

  def handle_call(@lock_msg, {pid, _ref}, %{drag_state: :free} = state) do
    {:reply, {:ok, :locked}, lock_drag(state, pid),
     {:continue, {@locked_cb, pid}}}
  end

  @impl GenServer
  def handle_cast(
        {@unlock_msg, from},
        %{drag_state: {:locked, from, _timer_ref}} = state
      ) do
    {:noreply, unlock_drag(state), {:continue, {@unlocked_cb, from}}}
  end

  def handle_cast({@unlock_msg, _from}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_continue({@on_start_cb, on_start}, state) do
    :ok = on_start.(state)

    {:noreply, state}
  end

  def handle_continue({@locked_cb, from}, state) do
    :ok = Channels.broadcast_playlist_dragging_locked!(from, state.id)

    {:noreply, state}
  end

  def handle_continue({@unlocked_cb, from}, state) do
    :ok = Channels.broadcast_playlist_dragging_unlocked!(from, state.id)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {@lock_timeout_cb, from},
        %{drag_state: {:locked, from, _timer_ref}} = state
      ) do
    Channels.notify_playlsit_dragging_cancelled(from, state.id)
    {:noreply, unlock_drag(state), {:continue, {@unlocked_cb, from}}}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    state = remove_member(state, ref)

    Logger.debug(
      "Member with pid=#{inspect(pid)} left with reason=#{inspect(reason)}"
    )

    {:noreply, state}
  end

  @spec add_member(state(), reference(), pid()) :: state()
  defp add_member(%{members: members} = state, ref, pid),
    do: %{state | members: Map.put(members, ref, pid)}

  @spec remove_member(state(), reference()) :: state()
  defp remove_member(%{members: members} = state, ref),
    do: %{state | members: Map.delete(members, ref)}

  @spec lock_drag(state(), pid()) :: state()
  defp lock_drag(state, pid), do: schedule_lock_timeout(state, pid)

  @spec unlock_drag(state()) :: state()
  defp unlock_drag(%{drag_state: {:locked, _from, timer_ref}} = state) do
    _cancel_timer = Process.cancel_timer(timer_ref)
    %{state | drag_state: :free}
  end

  @spec schedule_lock_timeout(state(), pid()) :: state()
  defp schedule_lock_timeout(%{lock_timeout: timeout} = state, from) do
    %{
      state
      | drag_state:
          {:locked, from,
           Process.send_after(self(), {@lock_timeout_cb, from}, timeout)}
    }
  end
end
