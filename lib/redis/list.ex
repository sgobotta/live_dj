defmodule Redis.List do
  @moduledoc """
  Abstraction module for the [LIST commands](https://redis.io/commands/?group=list)
  """
  require Logger

  @doc """
  Redis LPUSH command. [Docs](https://redis.io/commands/lpush/)
  """
  @spec push(String.t(), String.t()) :: {:ok, integer()} | {:error, any()}
  def push(key, value) do
    case Redix.command(:redix, ~w(LPUSH #{key} #{value})) do
      {:ok, _list_length} = res ->
        res

      {:error, error} = e ->
        Logger.error(
          "#{__MODULE__}.push/2 key=#{inspect(key)} value=#{inspect(value)} error=#{inspect(error)}"
        )

        e
    end
  end

  @doc """
  Redis LRANGE command. [Docs](https://redis.io/commands/lrange/)
  """
  @spec range(String.t()) :: Redis.redix_response()
  def range(key) do
    Redix.command(:redix, ~w(LRANGE #{key} 0 -1))
  end

  @doc """
  Given a key, a value, an insert strategy and an existent element, deletes the
  value from the list and immediately adds it before or after the given element.
  """
  @spec move(String.t(), String.t(), boolean(), Ecto.UUID.t()) ::
          Redis.redix_response()
  def move(key, value, position, element) do
    Redix.transaction_pipeline(:redix, [
      ~w(LREM #{key} 0 #{value}),
      ~w(LINSERT #{key} #{parse_position(position)} #{element} #{value})
    ])
  end

  @doc """
  Redis LPOS command. [Docs](https://redis.io/commands/lpos/)
  """
  @spec lpos(String.t(), String.t()) :: Redis.redix_response()
  def lpos(key, value) do
    Redix.command(:redix, ~w(LPOS #{key} #{value}))
  end

  @doc """
  Redis LREM command. [Docs](https://redis.io/commands/lrem/)
  """
  @spec lrem(String.t(), String.t()) :: Redis.redix_response()
  def lrem(key, value) do
    Redix.command(:redix, ~w(LREM #{key} 1 #{value}))
  end

  defp parse_position(true), do: "AFTER"
  defp parse_position(false), do: "BEFORE"
end
