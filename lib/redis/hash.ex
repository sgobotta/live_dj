defmodule Redis.Hash do
  @moduledoc """
  Abstraction module for the [HASH commands](https://redis.io/commands/?group=hash)
  """

  @doc """
  Redis HSET command. [Docs](https://redis.io/commands/hset/)
  """
  @spec hset(Ecto.UUID.t(), map()) :: {:ok, map()} | {:error, :hset_error}
  def hset(key, value) do
    fields =
      Enum.reduce(value, [], fn {k, v}, acc -> acc ++ [Atom.to_string(k), v] end)

    case Redix.command(:redix, ["HSET", key] ++ fields) do
      {:ok, n_fields} when is_integer(n_fields) ->
        {:ok, value}

      _other ->
        {:error, :hset_error}
    end
  end

  @doc """
  Redis HGETALL command. [Docs](https://redis.io/commands/hgetall/)
  """
  @spec hgetall(Ecto.UUID.t()) :: {:ok, map()} | {:error, :hash_not_found}
  def hgetall(key) do
    case Redix.command(:redix, ~w(HGETALL #{key})) do
      {:ok, []} ->
        {:error, :hash_not_found}

      {:ok, result} ->
        value =
          result
          |> Enum.chunk_every(2)
          |> Enum.map(fn [a, b] -> {a, b} end)
          |> Map.new()

        {:ok, value}
    end
  end
end
