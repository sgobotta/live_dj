# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :live_dj,
  ecto_repos: [LiveDj.Repo]

# Configures the endpoint
config :live_dj, LiveDjWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "eE2e6pkkr1eNnelAHPONdo7m7y62n1nAiujIgiTSvA97jf3QBZMzISlvSupW4ktk",
  render_errors: [view: LiveDjWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LiveDj.PubSub,
  live_view: [signing_salt: "giHzpJwl"]

config :live_dj, LiveDj.Mailer,
  adapter: Bamboo.SendGridAdapter,
  api_key: {:system, "SENDGRID_API_KEY"},
  hackney_opts: [
    recv_timeout: :timer.minutes(1)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
