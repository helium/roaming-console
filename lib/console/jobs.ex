defmodule Console.Jobs do
  # This module defines the jobs to be ran by Quantum scheduler
  # as defined in config/config.exs
  
  alias Console.Repo

  def refresh_materialized_views do
    Task.Supervisor.async_nolink(ConsoleWeb.TaskSupervisor, fn ->
      Ecto.Adapters.SQL.query!(Repo, "REFRESH MATERIALIZED VIEW packets_view", [], timeout: :infinity)
    end)
  end
end
