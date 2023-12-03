defmodule Livedj.Sessions.PlayerServer do
  @moduledoc """
  The Playlist Server implementation
  """
  use GenServer, restart: :transient

  alias Livedj.Sessions.Channels

  require Logger

  @join_msg :join
  @play_msg :play
  @pause_msg :pause

  @joined_cb :joined
  @playing_cb :playing
  @paused_cb :paused
  @ended_cb :ended
  @on_start_cb :on_start

  @lock_timeout :timer.seconds(15)

  @type state :: %{
          :id => binary(),
          :members => map()
        }

  @type element :: any()

  @type join_response :: {:ok, :joined}
  @type play_response :: :ok
  @type pause_response :: :ok

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
  @spec join(pid(), keyword()) :: join_response()
  def join(pid, cbs) do
    GenServer.call(pid, {@join_msg, cbs})
  end

  @doc """
  Given a pid, sends a play signal to the player.
  """
  @spec play(pid(), keyword()) :: play_response()
  def play(pid, cbs) do
    GenServer.call(pid, {@play_msg, cbs})
  end

  @doc """
  Given a pid, sends a pause signal to the player.
  """
  @spec pause(pid(), keyword()) :: pause_response()
  def pause(pid, cbs) do
    GenServer.call(pid, {@pause_msg, cbs})
  end

  @doc """
  Given a keyword of args returns a new map that represents the #{__MODULE__}
  state.
  """
  @spec initial_state(keyword()) :: state()
  def initial_state(opts) do
    %{
      id: Keyword.fetch!(opts, :id),
      members: Map.new()
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
  def handle_call({@join_msg, cbs}, {pid, _ref}, state) do
    ref = Process.monitor(pid)

    Logger.debug(
      "#{__MODULE__} :: User with pid: #{inspect(pid)} just joined the server."
    )

    state = add_member(state, ref, pid)

    {:reply, {:ok, :joined}, state, {:continue, {@joined_cb, pid, cbs}}}
  end

  def handle_call({@play_msg, _cbs}, _from, state) do
    # {{_on_play, _args}, _cbs} = Keyword.pop!(cbs, :on_play)
    {:reply, :ok, state}
  end

  def handle_call({@pause_msg, cbs}, {_pid, _ref}, state) do
    {{_on_pause, _args}, _cbs} = Keyword.pop!(cbs, :on_pause)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_continue({@on_start_cb, on_start}, state) do
    :ok = on_start.(state)

    {:noreply, state}
  end

  def handle_continue({@joined_cb, from, cbs}, state) do
    {{on_joined, args}, _cbs} = Keyword.pop!(cbs, :on_joined)

    case apply(on_joined, args) do
      {:ok, response} ->
        Channels.notify_player_joined(from, state.id, %{player: response})

      {:error, _error} ->
        :error
    end

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

  @spec add_member(state(), reference(), pid()) :: state()
  defp add_member(%{members: members} = state, ref, pid),
    do: %{state | members: Map.put(members, ref, pid)}

  @spec remove_member(state(), reference()) :: state()
  defp remove_member(%{members: members} = state, ref),
    do: %{state | members: Map.delete(members, ref)}
end
