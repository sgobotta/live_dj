defmodule Livedj.Sessions.Player do
  @moduledoc false

  defstruct id: nil, state: nil, media_id: nil

  @key_prefix "player"

  @type t :: %__MODULE__{}

  @spec initial_player(Ecto.UUID.t()) :: map()
  defp initial_player(id),
    do: %__MODULE__{
      id: id,
      state: :idle,
      media_id: nil
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
    Redis.Hash.hset(build_key(room_id), from_struct(initial_player(room_id)))
  end

  @doc """
  Given a room id returns the associated player.
  """
  @spec get(Ecto.UUID.t()) :: {:ok, t()} | {:error, :player_not_found}
  def get(room_id) do
    case Redis.Hash.hgetall(build_key(room_id)) do
      {:ok, map} ->
        {:ok, from_hset(map)}

      {:error, :hash_not_found} ->
        {:error, :player_not_found}
    end
  end

  @spec build_key(Ecto.UUID.t()) :: String.t()
  defp build_key(key), do: @key_prefix <> ":" <> key

  @doc """
  Given a Player, returns a map representation.
  """
  @spec from_struct(t()) :: map()
  def from_struct(%__MODULE__{id: id, state: state, media_id: media_id}),
    do: %{
      id: id,
      state: state,
      media_id: media_id
    }

  @doc """
  Given a Redis hash, returns a Player representation.
  """
  @spec from_hset(map()) :: t()
  def from_hset(%{"id" => id, "state" => state, "media_id" => media_id}) do
    %__MODULE__{
      id: id,
      state: state,
      media_id: media_id
    }
  end
end
