defmodule Livedj.Sessions.PlayerServer do
  @moduledoc """
  Per-room GenServer that coordinates player members and a single controller.

  The controller is the only member allowed to report YouTube lifecycle events
  (e.g. track ended). The first member to join becomes controller; when the
  controller disconnects, another member is promoted.
  """
  use GenServer, restart: :transient

  alias Livedj.Sessions.Channels

  require Logger

  @join_msg :join
  @play_msg :play
  @pause_msg :pause
  @state_change_msg :state_change
  @report_track_ended_msg :report_track_ended

  @joined_cb :joined
  @on_start_cb :on_start

  @type state :: %{
          :id => binary(),
          :controller => pid() | nil,
          :members => map()
        }

  @type join_response :: {:ok, :joined}
  @type state_change_response :: :ok
  @type play_response :: :ok
  @type pause_response :: :ok
  @type report_track_ended_response :: {:ok, :handled} | {:ok, :ignored}

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
  Reports that the current track ended in the YouTube player.

  Only the room controller's caller process may trigger the callback; other
  members receive `{:ok, :ignored}`.
  """
  @spec report_track_ended(pid(), keyword()) :: report_track_ended_response()
  def report_track_ended(pid, cbs) do
    GenServer.call(pid, {@report_track_ended_msg, cbs})
  end

  @doc """
  Given a keyword of args returns a new map that represents the #{__MODULE__}
  state.
  """
  @spec initial_state(keyword()) :: state()
  def initial_state(opts) do
    %{
      id: Keyword.fetch!(opts, :id),
      controller: nil,
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

    state =
      state
      |> add_member(ref, pid)
      |> maybe_elect_controller(pid)

    {:reply, {:ok, :joined}, state, {:continue, {@joined_cb, pid, cbs}}}
  end

  def handle_call({@report_track_ended_msg, cbs}, {caller, _ref}, state) do
    if controller?(state, caller) do
      {{on_track_ended, args}, []} = Keyword.pop!(cbs, :on_track_ended)

      :ok = apply(on_track_ended, args)

      {:reply, {:ok, :handled}, state}
    else
      Logger.debug(
        "#{__MODULE__} :: Ignoring track ended from non-controller pid=#{inspect(caller)}, controller=#{inspect(state.controller)}"
      )

      {:reply, {:ok, :ignored}, state}
    end
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

    state =
      if state.controller == pid do
        promote_controller(state)
      else
        state
      end

    Logger.debug(
      "Member with pid=#{inspect(pid)} left with reason=#{inspect(reason)}"
    )

    {:noreply, state}
  end

  @spec controller?(state(), pid()) :: boolean()
  defp controller?(%{controller: controller}, caller),
    do: controller != nil and controller == caller

  @spec add_member(state(), reference(), pid()) :: state()
  defp add_member(%{members: members} = state, ref, pid),
    do: %{state | members: Map.put(members, ref, pid)}

  @spec remove_member(state(), reference()) :: state()
  defp remove_member(%{members: members} = state, ref),
    do: %{state | members: Map.delete(members, ref)}

  @spec maybe_elect_controller(state(), pid()) :: state()
  defp maybe_elect_controller(%{controller: nil} = state, pid),
    do: %{state | controller: pid}

  defp maybe_elect_controller(state, _pid), do: state

  @spec promote_controller(state()) :: state()
  defp promote_controller(state) do
    case Map.values(state.members) do
      [] ->
        %{state | controller: nil}

      members ->
        controller = members |> Enum.sort() |> List.first()
        %{state | controller: controller}
    end
  end
end
