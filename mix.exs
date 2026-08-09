defmodule Livedj.MixProject do
  use Mix.Project

  def project do
    [
      app: :livedj,
      version: File.read!("version.txt"),
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # Docs
      name: "Livedj",
      source_url: "https://github.com/sgobotta/live_dj",
      docs: [
        main: "Livedj",
        extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Livedj.Application, []},
      extra_applications: [:logger, :runtime_tools, :tubex]
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
      # Authentication
      {:bcrypt_elixir, "~> 3.0"},
      # Code quality and Testing
      {:credo, "~> 1.6.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.15", only: [:test]},
      {:git_hooks, "~> 0.7.3", only: [:dev], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:test], runtime: false},
      # Documentation
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      # Phoenix default apps
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1"},
      {:lazy_html, ">= 0.0.0", only: :test},
      {:floki, ">= 0.30.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      # Youtube deps
      {:tubex, git: "https://github.com/sgobotta/tubex.git", tag: "0.0.11"},
      # Other
      {:faker, "~> 0.18"},
      {:html_entities, "~> 0.5.2"},
      {:phoenix_inline_svg, "~> 1.4"},
      {:poison, "~> 3.1"},
      {:redix, "~> 1.2"}
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
      # Run code checks
      check: [
        "check.format",
        "check.credo",
        "check.dialyzer"
      ],
      "check.format": ["format --check-formatted", "eslint"],
      "check.credo": ["credo --strict"],
      "check.dialyzer": ["dialyzer --format dialyxir"],
      eslint: ["cmd npm run eslint --prefix assets"],
      "eslint.fix": ["cmd npm run eslint-fix --prefix assets"],
      # Setup project
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      # Test
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      # Client setup
      "assets.setup": [
        "assets.install",
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.install": ["cmd npm i --prefix assets"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
