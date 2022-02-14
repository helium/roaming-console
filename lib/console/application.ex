defmodule Console.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      {Task.Supervisor, name: ConsoleWeb.TaskSupervisor},
      {Console.Repo, []},
      {ConsoleWeb.Endpoint, []},
      {Phoenix.PubSub, name: Console.PubSub},
      {Absinthe.Subscription, [ConsoleWeb.Endpoint]},
      {ConsoleWeb.Monitor, %{ address: "", packets_state: [], packets_error_state: [], amqp_conn: nil }},
      {ConsoleWeb.MessageQueuePublisher, %{}},
      {ConsoleWeb.MessageQueueConsumer, %{}},
      {Console.EtlWorker, %{}},
      {Console.EtlErrorWorker, %{}},
      Console.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Console.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ConsoleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
