defmodule LiveDj.Seeds.Utils do
  def date_to_naive_datetime("NULL"), do: nil
  def date_to_naive_datetime(datetime) do
    {:ok, naive_datetime} = Ecto.Type.cast(:naive_datetime, datetime)
    naive_datetime
  end

  def dates_to_naive_datetime(map, keys) do
    Enum.reduce(keys, %{}, fn (key, acc) ->
      Map.put(acc, key, date_to_naive_datetime(Map.get(map, key)))
    end)
  end
end
