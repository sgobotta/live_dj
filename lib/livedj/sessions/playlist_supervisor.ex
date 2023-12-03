defmodule Livedj.Sessions.PlaylistSupervisor do
  @moduledoc """
  Specific implementation for the Playlist Supervisor
  """
  use DynamicSupervisor

  require Logger

  alias Livedj.Sessions
  alias Livedj.Sessions.Exceptions.PlaylistServerError
  alias Livedj.Sessions.PlaylistServer

  @server_module PlaylistServer
  @registry_module Registry.Playlist

  @spec server_module() :: module()
  def server_module, do: @server_module

  @spec registry_module() :: module()
  def registry_module, do: @registry_module

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
        Logger.info("Starting #{length(rooms)} #{@server_module} process(es).")

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
  Given a reference and some arguments starts a `#{@server_module}` child and
  returns it's pid.
  """
  @spec start_child(module(), keyword()) :: {:ok, pid()}
  def start_child(supervisor \\ __MODULE__, args) do
    id = Keyword.fetch!(args, :id)

    on_start = fn state ->
      {:ok, _registry_pid} = Registry.register(@registry_module, id, state)

      :ok
    end

    args = Keyword.put(args, :on_start, on_start)

    DynamicSupervisor.start_child(supervisor, {server_module(), args})
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
  `#{@server_module}` pid and the second component the playlist server state.
  """
  @spec get_child(binary()) :: {pid(), map()} | nil
  def get_child(child_id) do
    case Registry.lookup(@registry_module, child_id) do
      [] ->
        nil

      [{_pid, _state} = child] ->
        child
    end
  end

  @doc """
  Given a room id, returns `nil` or a tuple where the first component is a
  `#{@server_module}` pid and the second component the playlist server state.
  """
  @spec get_child_pid!(binary()) :: pid()
  def get_child_pid!(child_id) do
    case get_child(child_id) do
      nil ->
        raise PlaylistServerError, reason: :child_not_found

      {pid, _state} when is_pid(pid) ->
        pid
    end
  end

  @doc """
  Given a reference and a child pid, terminates a `#{PlaylistServer}` process.
  """
  @spec terminate_child(module(), pid()) :: :ok | {:error, :not_found}
  def terminate_child(supervisor \\ __MODULE__, pid) do
    DynamicSupervisor.terminate_child(supervisor, pid)
  end
end
