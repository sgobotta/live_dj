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

  @doc """
  Returns true when a playing track has reached its stored duration.

  Elapsed time is measured with millisecond precision instead of going
  through `sync/1`'s second-truncated `current_time`, so the result
  isn't biased up to a second late on top of `epsilon`.
  """
  @spec track_ended?(Player.t(), number()) :: boolean()
  def track_ended?(player, epsilon \\ 0.25)

  def track_ended?(
        %Player{
          state: :playing,
          duration: duration,
          played_at: %DateTime{} = played_at,
          current_time: current_time
        },
        epsilon
      )
      when is_integer(duration) and duration > 0 do
    elapsed_ms = DateTime.diff(DateTime.utc_now(), played_at, :millisecond)
    position = to_integer(current_time) + elapsed_ms / 1000

    position >= duration - epsilon
  end

  def track_ended?(_player, _epsilon), do: false

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
