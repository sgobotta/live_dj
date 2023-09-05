defmodule Livedj.Media.MediaCache do
  @moduledoc false

  @key_prefix "media"

  @spec insert(String.t(), map()) :: {:ok, map()} | {:error, :hset_error}
  def insert(key, value) do
    Redis.Hash.hset(build_key(key), value)
  end

  @spec build_key(Ecto.UUID.t()) :: String.t()
  defp build_key(key), do: @key_prefix <> ":" <> key
end
