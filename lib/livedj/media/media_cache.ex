defmodule Livedj.Media.MediaCache do
  @moduledoc false

  @key_prefix "media"

  @doc """
  Given a key and a map, inserts the map in the cache and returns the result.
  """
  @spec insert(String.t(), map()) :: {:ok, map()} | {:error, :hset_error}
  def insert(key, value) do
    Redis.Hash.hset(build_key(key), value)
  end

  @doc """
  Given a key returns a map or `nil` whether the element exists or not.
  """
  @spec get(String.t()) :: map() | nil
  def get(key) do
    case Redis.Hash.hgetall(build_key(key)) do
      {:ok, map} ->
        map

      {:error, :hash_not_found} ->
        nil
    end
  end

  @spec build_key(Ecto.UUID.t()) :: String.t()
  defp build_key(key), do: @key_prefix <> ":" <> key
end
