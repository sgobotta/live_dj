defmodule Livedj.Seeds.Utils do
  @moduledoc """
  Utils for the Livedj seeds
  """

  require Logger

  @doc """
  Given a stringified date, casts it to a naive date time type.
  """
  @spec date_to_naive_datetime(binary()) :: nil | NaiveDateTime.t()
  def date_to_naive_datetime("NULL"), do: nil
  def date_to_naive_datetime(datetime) do
    {:ok, naive_datetime} = Ecto.Type.cast(:naive_datetime, datetime)
    naive_datetime
  end

  @doc """
  Given a map and a list of date keys, replaces existing date keys with a parsed
  value in the naive date time type to return a new map.
  """
  @spec dates_to_naive_datetime(map(), list(atom())) :: map()
  def dates_to_naive_datetime(map, keys) do
    Enum.reduce(keys, %{}, fn (key, acc) ->
      Map.put(acc, key, date_to_naive_datetime(Map.get(map, key)))
    end)
  end

  @doc """
  Handles errors on seeds creation.
  """
  @spec handle_error(any(), String.t()) :: :ok | any()
  def handle_error(%Postgrex.Error{postgres: %{code: code, constraint: constraint, detail: detail}} = error, resource) do
    log_key_violations(resource, code, constraint, detail, error)
  end

  def handle_error(error, resource) do
    :ok = Logger.error("Unhandled error while creating seeds for resource=#{resource} error=#{inspect(error)}")

    error
  end

  defp log_key_violations(resource, code, constraint, detail, _error) when code in [:unique_violation, :foreign_key_violation] do
    :ok = Logger.warn("❌ The #{resource} resource already exists, skipping creation. constraint=#{inspect(constraint)} detail=#{inspect(detail)}")
  end

  defp log_key_violations(resource, code, constraint, detail, error) do
    :ok = Logger.error("Unhandled Postgres error while creating seeds for resource=#{resource} code=#{inspect(code)} constraint=#{inspect(constraint)} detail=#{inspect(detail)}")

    error
  end

  defmacro __using__(opts) do
    quote do
      alias Livedj.Seeds.Utils

      require Logger

      [
        repo: repo,
        json_file_path: json_file_path,
        plural_element: plural_element,
        element_module: element_module,
        date_keys: date_keys
      ] = unquote(opts)

      @json_file_path json_file_path
      @plural_element plural_element
      @element_module element_module
      @date_keys date_keys

      @repo repo

      @doc """
      Given a json file dir, inserts all elements in the database for the given
      module schema.
      """
      @spec populate :: :ok
      def populate do
        file_path = "#{:code.priv_dir(:livedj)}/repo/seeds/#{@json_file_path}"

        with {:ok, body} <- File.read(file_path),
          {:ok, elements} <- Jason.decode(body, keys: :atoms) do

          elements = for element <- elements do
            Map.merge(element, Utils.dates_to_naive_datetime(element, @date_keys))
          end

          {count, _} = @repo.insert_all(@element_module, elements)

          :ok = Logger.info("✅ Inserted #{count} #{@plural_element}.")

          :ok
        end
      rescue
        error ->
          Utils.handle_error(error, @plural_element)
      end
    end
  end
end
