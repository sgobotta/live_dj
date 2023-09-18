defmodule Redis.Application do
  @moduledoc false

  def child_spec(_opts),
    do: Redix.child_spec(host: host!(), name: :redix, password: password!())

  def opts,
    do: [host: host!(), password: password!()]

  defp host!, do: Keyword.fetch!(env(), :redis_host)
  defp password!, do: Keyword.fetch!(env(), :redis_pass)
  defp env, do: Application.fetch_env!(:livedj, Redis)
end
