defmodule Livedj.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  require Logger

  @app :livedj

  def create_db do
    :ok = load_app()

    for repo <- repos() do
      Application.fetch_env!(@app, repo)
      |> repo.__adapter__().storage_up()
      |> case do
        :ok ->
          :ok = Logger.info("Database has been created")

        {:error, :already_up} ->
          :ok = Logger.info("Database is already up")

        {:error, error} ->
          :ok =
            Logger.error(
              "Error while trying to create database: #{inspect(error)}"
            )
      end
    end
  end

  def migrate do
    :ok = load_app()

    for repo <- repos() do
      if Application.fetch_env!(@app, repo)[:ssl] do
        {:ok, _apps} = Application.ensure_all_started(:ssl)
      end

      {:ok, _res, _apps} =
        Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    :ok = load_app()

    {:ok, _res, _apps} =
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Load seeds from file.
  """
  def seed(filename \\ "seeds.exs") do
    :ok = load_app()

    for repo <- repos() do
      {:ok, _a, _b} =
        Ecto.Migrator.with_repo(
          repo,
          &eval_seed(&1, filename, @app)
        )
    end
  end

  defp repos, do: Application.fetch_env!(@app, :ecto_repos)

  defp load_app do
    case Application.load(@app) do
      :ok ->
        :ok

      {:error, error} ->
        :ok =
          Logger.warn(
            "Error while loading application error=#{inspect(error, pretty: true)}"
          )
    end
  end

  defp eval_seed(repo, filename, app) do
    seeds_file = get_path(repo, filename, app)

    if File.regular?(seeds_file) do
      {:ok, Code.eval_file(seeds_file)}
    else
      {:error, "Seeds file not found."}
    end
  end

  defp get_path(repo, filename, app) do
    priv_dir = "#{:code.priv_dir(app)}"

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    Path.join([priv_dir, repo_underscore, filename])
  end
end
