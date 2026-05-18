defmodule Livedj.Sessions.VideoDuration do
  @moduledoc """
  Fetches and parses YouTube video duration via Tubex.
  """

  require Logger

  @youtube_duration ~r/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/

  @spec fetch_seconds(binary()) ::
          {:ok, non_neg_integer()} | {:error, :no_duration}
  def fetch_seconds(external_id) do
    external_id
    |> Tubex.Video.detail()
    |> duration_from_detail_response(external_id)
  end

  # Tubex.Video.detail/1 returns the decoded API body map on success, not {:ok, map()}.
  @spec duration_from_detail_response(term(), binary()) ::
          {:ok, non_neg_integer()} | {:error, :no_duration}
  defp duration_from_detail_response(
         %{"items" => [%{"contentDetails" => %{"duration" => iso}} | _]},
         _external_id
       ) do
    case parse_iso8601_duration(iso) do
      {:ok, seconds} -> {:ok, seconds}
      :error -> {:error, :no_duration}
    end
  end

  defp duration_from_detail_response({:error, _reason}, _external_id),
    do: {:error, :no_duration}

  defp duration_from_detail_response(response, external_id) do
    Logger.debug(
      "#{__MODULE__} :: No duration for external_id=#{external_id} response=#{inspect(response)}"
    )

    {:error, :no_duration}
  end

  @spec parse_iso8601_duration(binary()) :: {:ok, non_neg_integer()} | :error
  def parse_iso8601_duration(iso) when is_binary(iso) do
    case Regex.run(@youtube_duration, iso) do
      [_, hours, minutes, seconds] ->
        total =
          parse_component(hours) * 3600 +
            parse_component(minutes) * 60 +
            parse_component(seconds)

        if total > 0 do
          {:ok, total}
        else
          :error
        end

      _else ->
        :error
    end
  end

  def parse_iso8601_duration(_else), do: :error

  @spec parse_component(binary()) :: non_neg_integer()
  defp parse_component(""), do: 0

  defp parse_component(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _offset} when int >= 0 -> int
      _other_error -> 0
    end
  end
end
