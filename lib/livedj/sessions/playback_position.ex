defmodule Livedj.Sessions.PlaybackPosition do
  @moduledoc """
  Computes playback position from stored `current_time` and `played_at`.
  """

  alias Livedj.Sessions.Player

  @spec sync(Player.t()) :: Player.t()
  def sync(
        %Player{state: :playing, played_at: %DateTime{} = played_at} = player
      ) do
    base = to_integer(player.current_time)
    elapsed = DateTime.diff(DateTime.utc_now(), played_at, :second)

    %{player | current_time: max(0, base + elapsed)}
  end

  def sync(%Player{} = player),
    do: %{player | current_time: to_integer(player.current_time)}

  @spec to_integer(non_neg_integer() | binary() | any()) :: non_neg_integer()
  defp to_integer(value) when is_integer(value) and value >= 0, do: value

  defp to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _offset} when int >= 0 -> int
      _other_error -> 0
    end
  end

  defp to_integer(_else), do: 0
end
