defmodule Livedj.Sessions.PlaylistServer do
  @moduledoc """
  The Playlist Server implementation
  """
  use GenServer, restart: :transient

  alias Livedj.Sessions.Channels

  require Logger

  @timeout :timer.seconds(3600)

  @type state :: %{
          :id => binary(),
          :drag_state => {:locked, pid()} | :free,
          :members => map(),
          :timeout => pos_integer(),
          :timer_ref => reference() | nil
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
    GenServer.call(pid, :join)
  end

  @doc """
  Given a pid, locks the playlist drag.
  """
  @spec lock(pid()) :: lock_response()
  def lock(pid) do
    GenServer.call(pid, :lock)
  end

  @doc """
  Given a pid, unlocks the playlist drag.
  """
  @spec unlock(pid(), pid()) :: unlock_response()
  def unlock(pid, from) do
    GenServer.cast(pid, {:unlock, from})
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
      timeout: Keyword.get(opts, :timeout, @timeout),
      timer_ref: nil
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
     {:continue, {:on_start, Keyword.fetch!(init_args, :on_start)}}}
  end

  @impl GenServer
  def handle_call(:join, {pid, _ref}, state) do
    ref = Process.monitor(pid)

    Logger.debug(
      "#{__MODULE__} :: User with pid: #{inspect(pid)} just joined the server."
    )

    state = add_member(state, ref, pid)

    {:reply, {:ok, :joined}, state}
  end

  @impl GenServer
  def handle_call(:lock, from, %{drag_state: {:locked, from}} = state) do
    {:reply, {:error, :already_locked}, state}
  end

  def handle_call(:lock, _from, %{drag_state: {:locked, _pid}} = state) do
    {:reply, {:error, :not_an_owner}, state}
  end

  def handle_call(:lock, {pid, _ref}, %{drag_state: :free} = state) do
    {:reply, {:ok, :locked}, lock_drag(state, pid), {:continue, {:locked, pid}}}
  end

  @impl GenServer
  def handle_cast({:unlock, from}, state) do
    {:noreply, unlock_drag(state), {:continue, {:unlocked, from}}}
  end

  @impl GenServer
  def handle_continue({:on_start, on_start}, state) do
    :ok = on_start.(state)

    {:noreply, state}
  end

  def handle_continue({:locked, from}, state) do
    :ok = Channels.notify_playlist_dragging_locked(from, state.id)

    {:noreply, state}
  end

  def handle_continue({:unlocked, from}, state) do
    :ok = Channels.notify_playlist_dragging_unlocked(from, state.id)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    state = remove_member(state, ref)

    Logger.debug(
      "Member with pid=#{inspect(pid)} left with reason=#{inspect(reason)}"
    )

    {:noreply, state}
  end

  defp add_member(%{members: members} = state, ref, pid),
    do: %{state | members: Map.put(members, ref, pid)}

  defp remove_member(%{members: members} = state, ref),
    do: %{state | members: Map.delete(members, ref)}

  defp lock_drag(state, pid), do: Map.put(state, :drag_state, {:locked, pid})

  defp unlock_drag(state), do: Map.put(state, :drag_state, :free)
end
