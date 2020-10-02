defmodule LiveDj.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      LiveDj.Repo,
      # Start the Telemetry supervisor
      LiveDjWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveDj.PubSub},
      # Start our Presence module.
      LiveDjWeb.Presence,
      # Start the Endpoint (http/https)
      LiveDjWeb.Endpoint
      # Start a worker by calling: LiveDj.Worker.start_link(arg)
      # {LiveDj.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveDj.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LiveDjWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
