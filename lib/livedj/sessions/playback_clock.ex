defmodule Livedj.Sessions.PlaybackClock do
  @moduledoc """
  Per-room GenServer that owns play/pause timing, periodic end checks while playing,
  and advancing the playlist when the server clock reaches track duration.
  """
  use GenServer, restart: :transient

  alias Livedj.Sessions
  alias Livedj.Sessions.{PlaybackPosition, Player}

  require Logger

  @registry_module Registry.PlaybackClock
  @tick_interval :timer.seconds(1)
  @tick_msg :tick

  @type state :: %{
          id: binary(),
          tick_ref: reference() | nil,
          advancing: boolean()
        }

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

  @spec track_loaded(pid()) :: :ok
  def track_loaded(pid), do: GenServer.cast(pid, :track_loaded)

  @spec registry_module() :: module()
  def registry_module, do: @registry_module

  @impl GenServer
  def init(opts) do
    room_id = Keyword.fetch!(opts, :id)

    :ok =
      Logger.info(
        "#{__MODULE__} :: Started for room=#{room_id}, pid=#{inspect(self())}"
      )

    state = %{id: room_id, tick_ref: nil, advancing: false}
    {:ok, state, {:continue, :register}}
  end

  @impl GenServer
  def handle_continue(:register, %{id: room_id} = state) do
    {:ok, _} = Registry.register(@registry_module, room_id, state)
    {:noreply, state, {:continue, :schedule_tick}}
  end

  def handle_continue(:schedule_tick, state) do
    {:noreply, reschedule_tick(state)}
  end

  @impl GenServer
  def handle_call(:play, _from, state) do
    played_at = DateTime.utc_now()
    room_id = state.id

    reply =
      case Player.play(room_id, played_at: played_at) do
        {:ok, player} -> {:ok, PlaybackPosition.sync(player)}
        error -> error
      end

    {:reply, reply, reschedule_tick(%{state | advancing: false})}
  end

  def handle_call({:pause, opts}, _from, state) do
    at = Keyword.fetch!(opts, :at)
    room_id = state.id

    reply =
      case Player.pause(room_id, at: at) do
        {:ok, player} -> {:ok, PlaybackPosition.sync(player)}
        error -> error
      end

    {:reply, reply, cancel_tick(%{state | advancing: false})}
  end

  def handle_call(:sync_player, _from, %{id: room_id} = state) do
    reply =
      case Player.get(room_id) do
        {:ok, player} -> {:ok, PlaybackPosition.sync(player)}
        error -> error
      end

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_cast(:track_loaded, state) do
    {:noreply, reschedule_tick(%{state | advancing: false})}
  end

  def handle_cast(:advance_track, %{id: room_id} = state) do
    media_before = player_media_id(room_id)
    :ok = Sessions.next_track(room_id)
    media_after = player_media_id(room_id)

    state =
      if media_before == media_after do
        freeze_at_end(room_id)
        cancel_tick(%{state | advancing: false})
      else
        %{state | advancing: false}
      end

    {:noreply, state, {:continue, :schedule_tick}}
  end

  @impl GenServer
  def handle_info(@tick_msg, %{advancing: true} = state) do
    {:noreply, reschedule_tick(state)}
  end

  def handle_info(@tick_msg, %{id: room_id} = state) do
    state =
      case Player.get(room_id) do
        {:ok, player} ->
          if PlaybackPosition.track_ended?(player) do
            Logger.debug("#{__MODULE__} :: Track ended for room=#{room_id}")
            GenServer.cast(self(), :advance_track)
            %{state | advancing: true}
          else
            state
          end

        {:error, _} ->
          state
      end

    {:noreply, reschedule_tick(state)}
  end

  @spec reschedule_tick(state()) :: state()
  defp reschedule_tick(state) do
    state = cancel_tick(state)

    case playing?(state.id) do
      true ->
        ref = Process.send_after(self(), @tick_msg, @tick_interval)
        %{state | tick_ref: ref}

      false ->
        %{state | tick_ref: nil}
    end
  end

  @spec cancel_tick(state()) :: state()
  defp cancel_tick(%{tick_ref: ref} = state) when is_reference(ref) do
    _timer_response = Process.cancel_timer(ref)
    %{state | tick_ref: nil}
  end

  defp cancel_tick(state), do: state

  @spec playing?(binary()) :: boolean()
  defp playing?(room_id) do
    case Player.get(room_id) do
      {:ok, %Player{state: :playing}} -> true
      _else -> false
    end
  end

  @spec player_media_id(binary()) :: binary() | nil
  defp player_media_id(room_id) do
    case Player.get(room_id) do
      {:ok, %Player{media_id: media_id}} -> media_id
      _else -> nil
    end
  end

  @spec freeze_at_end(binary()) :: :ok
  defp freeze_at_end(room_id) do
    with {:ok, %Player{duration: duration}} <- Player.get(room_id),
         position when is_integer(position) <- duration || 0 do
      _player_response = Player.pause(room_id, at: position)
    end

    :ok
  end
end
