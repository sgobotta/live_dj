defmodule Redis do
  @moduledoc """
  Wrapper module for the Redix dep.
  """

  @type redix_response ::
          {:ok, Redix.Protocol.redis_value()}
          | {:error, atom() | Redix.Error.t() | Redix.ConnectionError.t()}

  defdelegate child_spec(opts), to: Redis.Application

  def set(key, value) do
    Redix.command(:redix, ["SET", key, value])
    |> parse_response()
  end

  def get(key) do
    Redix.command(:redix, ["GET", key])
    |> parse_response
  end

  def zadd(key, score, member) do
    Redix.command(:redix, ["ZADD", key, score, member])
    |> parse_response()
  end

  defp parse_response({:ok, r}), do: r
end
