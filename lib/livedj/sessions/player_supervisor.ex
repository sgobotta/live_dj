defmodule Livedj.Sessions.PlayerSupervisor do
  @moduledoc """
  Specific implementation for the Player Supervisor
  """
  use DynamicSupervisor

  require Logger

  alias Livedj.Sessions
  alias Livedj.Sessions.Exceptions.PlayerServerError
  alias Livedj.Sessions.{PlaybackClock, Player, PlayerServer}

  @server_module PlayerServer
  @clock_module PlaybackClock
  @registry_module Registry.Player
  @clock_registry_module Registry.PlaybackClock

  @spec server_module() :: module()
  def server_module, do: @server_module

  @spec registry_module() :: module()
  def registry_module, do: @registry_module

  @spec clock_module() :: module()
  def clock_module, do: @clock_module

  @spec clock_registry_module() :: module()
  def clock_registry_module, do: @clock_registry_module

  @doc """
  Given a keyword of args, initialises the dynamic Playlist Supervisor.
  """
  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(init_arg) do
    name = Keyword.get(init_arg, :name, __MODULE__)
    init_arg = Keyword.delete(init_arg, :name)

    {:ok, pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: name)

    Logger.info("#{__MODULE__} started with pid: #{inspect(pid)}")

    Sessions.list_rooms()
    |> then(fn rooms ->
      :ok =
        Logger.info("Starting #{length(rooms)} #{server_module()} process(es).")

      rooms
    end)
    |> Enum.each(fn %Sessions.Room{id: room_id} ->
      {:ok, _pid} = start_child(__MODULE__, id: room_id)
    end)

    {:ok, pid}
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Given a reference and some arguments starts a `#{PlayerServer}` child and
  returns it's pid.
  """
  @spec start_child(module(), keyword()) :: {:ok, pid()}
  def start_child(supervisor \\ __MODULE__, args) do
    id = Keyword.fetch!(args, :id)

    on_start = fn state ->
      {:ok, _response} = Player.maybe_initialise_player(id)
      {:ok, _registry_pid} = Registry.register(registry_module(), id, state)
      :ok
    end

    args = Keyword.put(args, :on_start, on_start)

    with {:ok, player_pid} <-
           DynamicSupervisor.start_child(supervisor, {server_module(), args}),
         {:ok, _clock_pid} <- start_playback_clock(supervisor, id) do
      {:ok, player_pid}
    end
  end

  @doc """
  Starts a `#{PlaybackClock}` for a room when one is not already running.
  """
  @spec start_playback_clock(module(), binary()) ::
          {:ok, pid()} | {:error, any()}
  def start_playback_clock(supervisor \\ __MODULE__, room_id) do
    case get_playback_clock(room_id) do
      {pid, _state} when is_pid(pid) ->
        {:ok, pid}

      nil ->
        DynamicSupervisor.start_child(
          supervisor,
          {@clock_module, [id: room_id]}
        )
    end
  end

  @doc """
  Returns `nil` or `{pid, state}` for the room's playback clock.
  """
  @spec get_playback_clock(binary()) :: {pid(), map()} | nil
  def get_playback_clock(room_id) do
    case Registry.lookup(@clock_registry_module, room_id) do
      [] -> nil
      [{pid, state}] -> {pid, state}
    end
  end

  @doc """
  Returns the playback clock pid for a room, raising if missing.
  """
  @spec get_playback_clock_pid!(binary()) :: pid()
  def get_playback_clock_pid!(room_id) do
    case get_playback_clock(room_id) do
      nil -> raise PlayerServerError, reason: :playback_clock_not_found
      {pid, _state} -> pid
    end
  end

  @doc """
  Given a reference returns all supervisor children pids.
  """
  @spec list_children(module()) :: [pid()]
  def list_children(supervisor \\ __MODULE__) do
    DynamicSupervisor.which_children(supervisor)
    |> Enum.filter(fn
      {_id, pid, :worker, _modules} when is_pid(pid) -> true
      _child -> false
    end)
    |> Enum.map(fn {_id, pid, :worker, _modules} -> pid end)
  end

  @doc """
  Given a room id, returns `nil` or a tuple where the first component is a
  `#{PlayerServer}` pid and the second component the playlist server state.
  """
  @spec get_child(binary()) :: {pid(), map()} | nil
  def get_child(child_id) do
    case Registry.lookup(registry_module(), child_id) do
      [] ->
        nil

      [{_pid, _state} = child] ->
        child
    end
  end

  @doc """
  Given a room id, returns `nil` or a tuple where the first component is a
  `#{PlayerServer}` pid and the second component the playlist server state.
  """
  @spec get_child_pid!(binary()) :: pid()
  def get_child_pid!(child_id) do
    case get_child(child_id) do
      nil ->
        raise PlayerServerError, reason: :child_not_found

      {pid, _state} when is_pid(pid) ->
        pid
    end
  end

  @doc """
  Given a reference and a child pid, terminates a `#{PlayerServer}` process.
  """
  @spec terminate_child(module(), pid()) :: :ok | {:error, :not_found}
  def terminate_child(supervisor \\ __MODULE__, pid) do
    DynamicSupervisor.terminate_child(supervisor, pid)
  end
end
