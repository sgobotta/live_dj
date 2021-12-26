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
        :tubex,
        :logger,
        :runtime_tools,
        :bamboo,
        :logger_file_backend
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "priv/repo/seeds", "test/support"]
  defp elixirc_paths(_), do: ["lib", "priv/repo/seeds"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Code quality and Testing
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:git_hooks, "~> 0.6.2", only: [:dev], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev], runtime: false},
      {:faker, "~> 0.16"},
      {:sobelow, "~> 0.11", only: [:dev, :test], runtime: false},
      # Documentation
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      # Email configuration
      {:bamboo, "~> 1.6"},
      # Default Elixir deps
      {:bcrypt_elixir, "~> 2.0"},
      {:logger_file_backend, "~> 0.0.11"},
      {:uuid, "~> 1.1"},
      # Default Phoenix deps
      {:floki, ">= 0.27.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.6.5"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 3.1.0"},
      {:phoenix_live_dashboard, "~> 0.2"},
      {:phoenix_live_reload, "~> 1.3.3", only: :dev},
      {:phoenix_live_view, "~> 0.17.5"},
      {:plug_cowboy, "~> 2.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      # Persistance
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      # Others & Helpers
      {:html_entities, "~> 0.5.2"},
      {:phoenix_inline_svg, "~> 1.4.0"},
      {:poison, "~> 3.1"},
      # Youtube deps
      {:tubex, git: "https://github.com/sgobotta/tubex.git", tag: "0.0.10"},
      # i18n and l10n
      {:tzdata, "~> 1.1"}
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
      # General Setup and installation tasks
      install: ["install.server", "install.client"],
      "install.server": ["deps.get", "deps.compile", "compile"],
      "install.client": ["cmd npm install --prefix assets"],
      # setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      setup: ["install", "reset.ecto"],

      # Persistance Setup tasks
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],

      # Run code checks
      lint: ["format.check", "eslint"],
      "format.check": ["format --check-formatted"],
      eslint: ["cmd npm run eslint --prefix assets"],
      "eslint.fix": ["cmd npm run eslint-fix --prefix assets"],
      check: [
        "check.format",
        "check.credo",
        "check.dialyzer"
      ],
      "check.format": ["cmd mix lint"],
      "check.credo": ["credo --strict"],
      "check.dialyzer": ["dialyzer --format dialyxir"],

      # Reset tasks
      "deps.reset": ["deps.reset.server", "deps.reset.client"],
      "deps.reset.server": ["deps.clean --all"],
      "deps.reset.client": ["cmd npm clean-install --prefix assets"],
      "reset.ecto": ["ecto.drop", "ecto.setup"],
      reset: ["ecto.drop", "deps.reset", "setup"],

      # Test tasks
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
