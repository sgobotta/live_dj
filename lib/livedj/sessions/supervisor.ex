defmodule Livedj.Sessions.Supervisor do
  @moduledoc """
  Generic implementation for the Room Supervisor
  """
  use Supervisor

  alias Livedj.Sessions.PlaylistSupervisor

  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Registry, keys: :unique, name: Registry.Playlist},
      {PlaylistSupervisor, []}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
