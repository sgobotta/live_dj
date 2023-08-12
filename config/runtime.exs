import Config

require Logger

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/livedj start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :livedj, LivedjWeb.Endpoint, server: true
end

config :livedj, stage: System.fetch_env!("STAGE")

config :livedj, Redis,
  redis_host: System.fetch_env!("REDIS_HOST"),
  redis_pass: System.fetch_env!("REDIS_PASS")

if config_env() == :prod do
  maybe_ipv6 =
    if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :livedj, Livedj.Repo,
    # ssl: true,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    show_sensitive_data_on_connection_error: false

  host = System.fetch_env!("PHX_HOST")
  port = String.to_integer(System.get_env("PORT", "443"))

  case System.get_env("STAGE") do
    "local" ->
      :ok =
        Logger.warn(
          "Ignoring variable DATABASE_URL as Postgrex connection protocol, proceding with default tcp connection."
        )

      config(:livedj, Livedj.Repo,
        database: System.get_env("DB_DATABASE"),
        username: System.fetch_env!("DB_USERNAME"),
        password: System.fetch_env!("DB_PASSWORD"),
        hostname: System.fetch_env!("DB_HOSTNAME")
      )

      config :livedj, LivedjWeb.Endpoint,
        http: [
          port: port,
          transport_options: [socket_opts: [:inet6]]
        ],
        url: [host: host, port: 80]

    _stage ->
      :ok = Logger.info("Using DATABASE_URL as Postgrex connection protocol.")

      database_url =
        System.get_env("DATABASE_URL") ||
          raise """
          environment variable DATABASE_URL is missing.
          For example: ecto://USER:PASS@HOST/DATABASE
          """

      config :livedj, Livedj.Repo,
        ssl: true,
        url: database_url

      config :livedj, LivedjWeb.Endpoint,
        http: [
          # Enable IPv6 and bind on all interfaces.
          # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
          # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
          # for details about using IPv6 vs IPv4 and loopback vs public addresses.
          # ip: {0, 0, 0, 0, 0, 0, 0, 0},
          port: {:system, "PORT"}
        ],
        url: [scheme: "https", host: host, port: port]
  end

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :livedj, LivedjWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :livedj, LivedjWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
  #

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :livedj, LivedjWeb.Endpoint,
    server: true,
    secret_key_base: secret_key_base

  # ----------------------------------------------------------------------------
  # Email configuration
  #
  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :livedj, Livedj.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
  #

  config :livedj, from_email: System.fetch_env!("LIVEDJ_FROM_EMAIL")

  config :livedj, Livedj.Mailer, api_key: System.fetch_env!("SENDGRID_API_KEY")
end
