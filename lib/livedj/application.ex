defmodule Livedj.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LivedjWeb.Telemetry,
      # Start the Ecto repository
      Livedj.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Livedj.PubSub},
      # Start Finch
      {Finch, name: Livedj.Finch},
      # Start the Endpoint (http/https)
      LivedjWeb.Endpoint
      # Start a worker by calling: Livedj.Worker.start_link(arg)
      # {Livedj.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Livedj.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LivedjWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
