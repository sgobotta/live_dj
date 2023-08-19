defmodule Livedj.Sessions.PlaylistServer do
  @moduledoc """
  The Playlist Server implementation
  """
  use GenServer, restart: :transient

  require Logger

  @timeout :timer.seconds(3600)

  @type state :: %{
          :id => binary(),
          :members => map(),
          :timeout => pos_integer(),
          :timer_ref => reference() | nil
        }

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
  @spec lock(pid()) :: {:ok, :locked}
  def lock(pid) do
    GenServer.call(pid, :lock)
  end

  @doc """
  Given a pid, unlocks the playlist drag.
  """
  @spec unlock(pid()) :: :ok
  def unlock(pid) do
    GenServer.cast(pid, :unlock)
  end

  @doc """
  Given a keyword of args returns a new map that represents the #{__MODULE__}
  state.
  """
  @spec initial_state(keyword()) :: state()
  def initial_state(opts) do
    %{
      id: Keyword.fetch!(opts, :id),
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
     {:continue, Keyword.fetch!(init_args, :on_start)}}
  end

  @impl GenServer
  def handle_continue(on_start, state) do
    :ok = on_start.(state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:join, {pid, _ref}, state) do
    ref = Process.monitor(pid)

    Logger.debug(
      "#{__MODULE__} :: User with pid: #{inspect(pid)} just joined the server."
    )

    state = %{
      state
      | members: Map.put(state.members, ref, pid)
    }

    {:reply, {:ok, :joined}, state}
  end

  @impl GenServer
  def handle_call(:lock, _from, state) do
    {:reply, {:ok, :locked}, state}
  end

  @impl GenServer
  def handle_cast(:unlock, state) do
    {:noreply, state}
  end
end
