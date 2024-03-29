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
  @state_change_msg :state_change

  @joined_cb :joined
  # @playing_cb :playing
  # @paused_cb :paused
  # @ended_cb :ended
  @on_start_cb :on_start

  @type state :: %{
          :id => binary(),
          :members => map()
        }

  @type element :: any()

  @type join_response :: {:ok, :joined}
  @type state_change_response :: :ok
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
  Given a pid, notifies the player state.
  """
  @spec state_change(pid(), keyword()) :: state_change_response()
  def state_change(pid, cbs) do
    GenServer.cast(pid, {@state_change_msg, cbs})
  end

  @doc """
  Given a pid, sends a play signal to the player.
  """
  @spec play(pid(), keyword()) :: play_response()
  def play(pid, cbs) do
    GenServer.cast(pid, {@play_msg, cbs})
  end

  @doc """
  Given a pid, sends a pause signal to the player.
  """
  @spec pause(pid(), keyword()) :: pause_response()
  def pause(pid, cbs) do
    GenServer.cast(pid, {@pause_msg, cbs})
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

  @impl GenServer
  def handle_cast({@state_change_msg, cbs}, state) do
    {{on_state_change, args}, []} = Keyword.pop!(cbs, :on_state_change)

    :ok = apply(on_state_change, args)

    {:noreply, state}
  end

  def handle_cast({@play_msg, cbs}, state) do
    {{on_play, args}, []} = Keyword.pop!(cbs, :on_play)

    :ok = apply(on_play, args)

    {:noreply, state}
  end

  def handle_cast({@pause_msg, cbs}, state) do
    {{on_pause, args}, []} = Keyword.pop!(cbs, :on_pause)

    :ok = apply(on_pause, args)

    {:noreply, state}
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
