defmodule Livedj.Sessions.Player do
  @moduledoc false

  @derive {Jason.Encoder, only: [:id, :state, :media_id, :current_time]}
  defstruct id: nil, state: nil, media_id: nil, current_time: 0

  @key_prefix "player"

  @type t :: %__MODULE__{}
  @type player_opts :: [
          {:seek_to, non_neg_integer()}
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
      current_time: 0
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
    params = maybe_merge_opts(%{media_id: media.external_id}, opts)

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
    case set(room_id, %{media_id: nil}) do
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
  def play(room_id, _opts) do
    case set(room_id, %{state: @playing_state}) do
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
    case set(room_id, %{current_time: current_time, state: @paused_state}) do
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
        current_time: current_time
      }),
      do: %{
        id: id,
        state: state,
        media_id: media_id,
        current_time: current_time
      }

  @doc """
  Given a Redis hash, returns a Player representation.
  """
  @spec from_hset(map()) :: t()
  def from_hset(%{
        "id" => id,
        "state" => state,
        "media_id" => media_id,
        "current_time" => current_time
      }) do
    %__MODULE__{
      id: id,
      state: String.to_existing_atom(state),
      media_id: media_id,
      current_time: current_time
    }
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
