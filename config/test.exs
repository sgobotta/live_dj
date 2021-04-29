use Mix.Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :live_dj, LiveDj.Repo,
  username: System.get_env("DB_USERNAME_TEST"),
  password: System.get_env("DB_PASSWORD_TEST"),
  database: "live_dj_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  timeout: :infinity

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :live_dj, LiveDjWeb.Endpoint,
  http: [port: 4002],
  server: false

config :tubex, Tubex, api_key: System.get_env("YOUTUBE_TEST_API_KEY")

config :live_dj, LiveDj.Mailer, adapter: Bamboo.TestAdapter

# Print only warnings and errors during test
config :logger, level: :warn
