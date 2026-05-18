defmodule Livedj.Sessions.PlaybackClock do
  @moduledoc """
  Per-room GenServer that owns play/pause timing for server-authoritative position.

  Phase 2a: records `played_at` on play, clears it on pause, and exposes synced position.
  Tick-based end detection is deferred to a later phase.
  """
  use GenServer, restart: :transient

  alias Livedj.Sessions.{PlaybackPosition, Player}

  require Logger

  @registry_module Registry.PlaybackClock

  @type state :: %{id: binary()}

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec play(pid()) :: {:ok, Player.t()} | {:error, any()}
  def play(pid), do: GenServer.call(pid, :play)

  @spec pause(pid(), keyword()) :: {:ok, Player.t()} | {:error, any()}
  def pause(pid, opts), do: GenServer.call(pid, {:pause, opts})

  @spec sync_player(pid()) :: {:ok, Player.t()} | {:error, any()}
  def sync_player(pid), do: GenServer.call(pid, :sync_player)

  @spec registry_module() :: module()
  def registry_module, do: @registry_module

  @impl GenServer
  def init(opts) do
    room_id = Keyword.fetch!(opts, :id)

    :ok =
      Logger.info(
        "#{__MODULE__} :: Started for room=#{room_id}, pid=#{inspect(self())}"
      )

    {:ok, %{id: room_id}, {:continue, :register}}
  end

  @impl GenServer
  def handle_continue(:register, %{id: room_id} = state) do
    {:ok, _} = Registry.register(@registry_module, room_id, state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:play, _from, %{id: room_id} = state) do
    played_at = DateTime.utc_now()

    reply =
      case Player.play(room_id, played_at: played_at) do
        {:ok, player} -> {:ok, PlaybackPosition.sync(player)}
        error -> error
      end

    {:reply, reply, state}
  end

  def handle_call({:pause, opts}, _from, %{id: room_id} = state) do
    at = Keyword.fetch!(opts, :at)

    reply =
      case Player.pause(room_id, at: at) do
        {:ok, player} -> {:ok, PlaybackPosition.sync(player)}
        error -> error
      end

    {:reply, reply, state}
  end

  def handle_call(:sync_player, _from, %{id: room_id} = state) do
    reply =
      case Player.get(room_id) do
        {:ok, player} -> {:ok, PlaybackPosition.sync(player)}
        error -> error
      end

    {:reply, reply, state}
  end
end
