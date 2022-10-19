defmodule Mrgr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Appsignal.Phoenix.LiveView.attach()

    children = [
      Mrgr.Repo,
      MrgrWeb.Telemetry,
      {Phoenix.PubSub, name: Mrgr.PubSub},
      MrgrWeb.Endpoint,
      Mrgr.PubSubConsumer,
      {Oban, Application.fetch_env!(:mrgr, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mrgr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MrgrWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
