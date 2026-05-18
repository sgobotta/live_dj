defmodule Livedj.Sessions.Player do
  @moduledoc false

  @derive {Jason.Encoder,
           only: [
             :id,
             :state,
             :media_id,
             :media_thumbnail_url,
             :current_time,
             :title,
             :channel
           ]}
  defstruct id: nil,
            state: nil,
            media_id: nil,
            media_thumbnail_url: nil,
            current_time: 0,
            played_at: nil,
            duration: nil,
            title: nil,
            channel: nil

  @key_prefix "player"

  @type t :: %__MODULE__{}
  @type player_opts :: [
          {:seek_to, non_neg_integer()},
          {:played_at, DateTime.t()},
          {:duration, non_neg_integer()},
          {:autoplay, boolean()}
        ]

  @idle_state :idle
  @playing_state :playing
  @paused_state :paused

  @type state :: :idle | :playing | :paused

  @spec initial_player(Ecto.UUID.t()) :: map()
  defp initial_player(id),
    do: %__MODULE__{
      id: id,
      state: @idle_state,
      media_id: nil,
      media_thumbnail_url: nil,
      current_time: 0,
      title: nil,
      channel: nil
    }

  @doc """
  Given an id, fetches a hash from redis. If it does not exit, sets a new hash.
  """
  @spec maybe_initialise_player(Ecto.UUID.t()) ::
          {:ok, :initialised} | {:ok, :noop}
  def maybe_initialise_player(room_id) do
    case get(room_id) do
      {:error, :player_not_found} ->
        new(room_id)
        {:ok, :initialised}

      {:ok, %__MODULE__{}} ->
        {:ok, :noop}
    end
  end

  @doc """
  Assigns a new player in the redis hash.
  """
  @spec new(Ecto.UUID.t()) :: Redis.redix_response()
  def new(room_id) do
    set(room_id, from_struct(initial_player(room_id)))
  end

  @doc """
  Given a room id returns the associated player.
  """
  @spec get(Ecto.UUID.t()) :: {:ok, t()} | {:error, :player_not_found}
  def get(room_id) do
    case Redis.Hash.hgetall(build_key(room_id)) do
      {:ok, player} ->
        {:ok, from_hset(player)}

      {:error, :hash_not_found} ->
        {:error, :player_not_found}
    end
  end

  @doc """
  Given a room_id, set a map of changes to the associated player.
  """
  @spec set(Ecto.UUID.t(), map()) :: {:ok, map()} | {:error, :hset_error}
  def set(room_id, changes),
    do: Redis.Hash.hset(build_key(room_id), changes)

  @doc """
  Given a room id sets a media id and returns a player struct.
  """
  @spec load_media(Ecto.UUID.t(), Livedj.Media.Video.t(), player_opts()) ::
          {:ok, t()} | {:error, :player_load_media_error | :player_not_found}
  def load_media(room_id, media, opts) do
    params =
      %{
        media_id: media.external_id,
        media_thumbnail_url: media.thumbnail_url,
        title: media.title,
        channel: media.channel
      }
      |> maybe_merge_opts(opts)
      |> maybe_merge_duration(opts)
      |> apply_load_playback_state(opts)

    case set(room_id, params) do
      {:ok, _changes} ->
        get(room_id)

      {:error, :hset_error} ->
        {:error, :player_load_media_error}
    end
  end

  @doc """
  Given a room id unsets the media id and returns a player struct.
  """
  @spec clear_media(Ecto.UUID.t()) ::
          {:ok, t()} | {:error, :player_clear_media_error | :player_not_found}
  def clear_media(room_id) do
    case set(room_id, %{media_id: nil, duration: ""}) do
      {:ok, _changes} ->
        get(room_id)

      {:error, :hset_error} ->
        {:error, :player_clear_media_error}
    end
  end

  @doc """
  Given a room id sets the current time to return a player struct.
  """
  @spec set_current_time(Ecto.UUID.t(), non_neg_integer()) ::
          {:ok, t()}
          | {:error, :player_set_current_time_error | :player_not_found}
  def set_current_time(room_id, current_time) do
    case set(room_id, %{current_time: current_time}) do
      {:ok, _changes} ->
        get(room_id)

      {:error, :hset_error} ->
        {:error, :player_set_current_time_error}
    end
  end

  @doc """
  Updates player state to playing
  """
  @spec play(Ecto.UUID.t(), keyword()) ::
          {:ok, t()}
          | {:error, :player_update_play_state_error | :player_not_found}
  def play(room_id, opts \\ []) do
    played_at =
      case Keyword.get(opts, :played_at) do
        %DateTime{} = dt -> DateTime.to_iso8601(dt)
        _else -> DateTime.utc_now() |> DateTime.to_iso8601()
      end

    case set(room_id, %{state: @playing_state, played_at: played_at}) do
      {:ok, _changes} ->
        get(room_id)

      {:error, :hset_error} ->
        {:error, :player_update_play_state_error}
    end
  end

  @doc """
  Updates player state to paused
  """
  @spec pause(Ecto.UUID.t(), keyword()) ::
          {:ok, t()}
          | {:error, :player_update_pause_state_error | :player_not_found}
  def pause(room_id, at: current_time) do
    case set(room_id, %{
           current_time: current_time,
           state: @paused_state,
           played_at: ""
         }) do
      {:ok, _changes} ->
        get(room_id)

      {:error, :hset_error} ->
        {:error, :player_update_pause_state_error}
    end
  end

  @spec build_key(Ecto.UUID.t()) :: String.t()
  defp build_key(key), do: @key_prefix <> ":" <> key

  @doc """
  Given a Player, returns a map representation.
  """
  @spec from_struct(t()) :: map()
  def from_struct(%__MODULE__{
        id: id,
        state: state,
        media_id: media_id,
        media_thumbnail_url: media_thumbnail_url,
        current_time: current_time,
        title: title,
        channel: channel
      }),
      do: %{
        id: id,
        state: state,
        media_id: media_id,
        media_thumbnail_url: media_thumbnail_url,
        current_time: current_time,
        title: title,
        channel: channel
      }

  @doc """
  Given a Redis hash, returns a Player representation.
  """
  @spec from_hset(map()) :: t()
  def from_hset(hset),
    do:
      Enum.reduce(hset, %__MODULE__{}, fn {k, v}, acc ->
        key = String.to_atom(k)
        Map.put(acc, key, parse_hset_value(key, v))
      end)

  @spec parse_hset_value(atom(), any()) :: any()
  defp parse_hset_value(:state, value), do: String.to_atom(value)

  defp parse_hset_value(:current_time, value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _offset} when int >= 0 -> int
      _other_error -> 0
    end
  end

  defp parse_hset_value(:current_time, value) when is_integer(value), do: value

  defp parse_hset_value(:played_at, ""), do: nil
  defp parse_hset_value(:played_at, nil), do: nil

  defp parse_hset_value(:played_at, value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      _other_error -> nil
    end
  end

  defp parse_hset_value(:duration, ""), do: nil
  defp parse_hset_value(:duration, nil), do: nil

  defp parse_hset_value(:duration, value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _offset} when int > 0 -> int
      _other_error -> nil
    end
  end

  defp parse_hset_value(:duration, value) when is_integer(value) and value > 0,
    do: value

  defp parse_hset_value(_key, value), do: value

  @spec maybe_merge_duration(map(), player_opts()) :: map()
  defp maybe_merge_duration(params, opts) do
    case Keyword.get(opts, :duration) do
      duration when is_integer(duration) and duration > 0 ->
        Map.put(params, :duration, duration)

      _else ->
        Map.put(params, :duration, "")
    end
  end

  # Clears timing from the previous track so the playback clock does not
  # treat the new load as already finished.
  @spec apply_load_playback_state(map(), player_opts()) :: map()
  defp apply_load_playback_state(params, opts) do
    if Keyword.get(opts, :autoplay, false) do
      params
      |> Map.put(:state, @playing_state)
      |> Map.put(:played_at, DateTime.utc_now() |> DateTime.to_iso8601())
    else
      params
      |> Map.put(:state, @paused_state)
      |> Map.put(:played_at, "")
    end
  end

  @spec maybe_merge_opts(map(), player_opts()) :: map()
  defp maybe_merge_opts(params, opts) do
    case Keyword.get(opts, :seek_to) do
      seek_to when is_integer(seek_to) ->
        Map.put(params, :current_time, seek_to)

      _else ->
        params
    end
  end
end
