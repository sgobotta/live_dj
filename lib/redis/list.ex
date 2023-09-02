defmodule Redis.List do
  @moduledoc """
  Abstraction module for the [LIST commands](https://redis.io/commands/?group=list)
  """

  @type redix_response ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}

  @doc """
  Redis LPUSH command. [Docs](https://redis.io/commands/lpush/)
  """
  @spec push(String.t(), Ecto.UUID.t()) :: redix_response()
  def push(key, value) do
    Redix.command(:redix, ~w(LPUSH #{key} #{value}))
  end

  @doc """
  Redis LRANGE command. [Docs](https://redis.io/commands/lrange/)
  """
  @spec range(String.t()) :: redix_response()
  def range(key) do
    Redix.command(:redix, ~w(LRANGE #{key} 0 -1))
  end

  @doc """
  Given a key, a value, an insert strategy and an existent element, deletes the
  value from the list and immediately adds it before or after the given element.
  """
  @spec move(String.t(), Ecto.UUID.t(), boolean(), Ecto.UUID.t()) ::
          redix_response()
  def move(key, value, position, element) do
    Redix.transaction_pipeline(:redix, [
      ~w(LREM #{key} 0 #{value}),
      ~w(LINSERT #{key} #{parse_position(position)} #{element} #{value})
    ])
  end

  defp parse_position(true), do: "AFTER"
  defp parse_position(false), do: "BEFORE"
end
