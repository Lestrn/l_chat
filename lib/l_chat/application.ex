defmodule LChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LChatWeb.Telemetry,
      LChat.Repo,
      {DNSCluster, query: Application.get_env(:l_chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LChat.PubSub},
      LChatWeb.Presence,
      # Start the Finch HTTP client for sending emails
      {Finch, name: LChat.Finch},
      # Start a worker by calling: LChat.Worker.start_link(arg)
      # {LChat.Worker, arg},
      # Start to serve requests, typically the last entry
      LChatWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
