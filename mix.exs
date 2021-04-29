defmodule LiveDj.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_dj,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {LiveDj.Application, []},
      extra_applications: [
        :tubex, :logger, :runtime_tools, :bamboo, :logger_file_backend
      ],
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bamboo, "~> 1.6"},
      {:bcrypt_elixir, "~> 2.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.4"},
      {:excoveralls, "~> 0.10", only: :test},
      {:faker, "~> 0.16"},
      {:floki, ">= 0.27.0"},
      {:git_hooks, "~> 0.6.2", only: [:dev], runtime: false},
      {:gettext, "~> 0.11"},
      {:html_entities, "~> 0.5.2"},
      {:jason, "~> 1.0"},
      {:logger_file_backend, "~> 0.0.11"},
      {:phoenix, "~> 1.5.5"},
      {:phoenix_ecto, "~> 4.1"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.14.6"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_inline_svg, "~> 1.4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.2"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:sobelow, "~> 0.11", only: [:dev, :test], runtime: false},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:tubex, git: "https://github.com/sgobotta/tubex.git", tag: "0.0.10"},
      {:tzdata, "~> 1.1"},
      {:uuid, "~> 1.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
