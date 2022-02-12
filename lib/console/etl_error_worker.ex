defmodule Console.EtlErrorWorker do
  use GenServer
  alias Console.Organizations
  alias Console.NetIds

  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(_opts) do
    if Application.get_env(:console, :use_amqp_events) do
      schedule_events_error_etl(10)
    end
    {:ok, %{}}
  end

  def handle_info(:run_events_error_etl, state) do
    events = ConsoleWeb.Monitor.get_events_error_state()

    Task.Supervisor.async_nolink(ConsoleWeb.TaskSupervisor, fn ->
      try do
        event = List.last(events)
        if event != nil do
          IO.inspect "PROCESSING EVENT FROM ETL ERROR WORKER..."
          parsed_event = event |> Jason.decode!() |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

          org = Organizations.get_organization!(parsed_event.organization_id)
          org_attrs = %{
            "dc_balance" => Enum.max([org.dc_balance - parsed_event.dc_used, 0]),
          }
          ConsoleWeb.Monitor.remove_from_events_error_state()

          with {:ok, _} <- Organizations.update_organization(org, org_attrs) do
            ConsoleWeb.Monitor.remove_from_events_error_state()
            if org.dc_balance - parsed_event.dc_used <= 0 do
              net_id_values = NetIds.get_all_for_organization(org.id) |> Enum.map(fn n -> n.value end)
              ConsoleWeb.Endpoint.broadcast("net_id:all", "net_id:all:stop_purchasing", %{ net_ids: net_id_values})
            end
          end
        end
      rescue
        error ->
          ConsoleWeb.Monitor.remove_from_events_error_state()
          Appsignal.send_error(error, "Failed to process in ETL Error Worker", ["etl_error_worker"])
      end
    end)
    |> Task.await(:infinity)

    schedule_events_error_etl(1)
    {:noreply, state}
  end

  defp schedule_events_error_etl(wait_time) do
    Process.send_after(self(), :run_events_error_etl, wait_time)
  end
end