defmodule Console.EtlErrorWorker do
  use GenServer
  alias Console.Organizations
  alias Console.NetIds

  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(_opts) do
    schedule_packets_error_etl(10)
    {:ok, %{}}
  end

  def handle_info(:run_packets_error_etl, state) do
    packets = ConsoleWeb.Monitor.get_packets_error_state()

    Task.Supervisor.async_nolink(ConsoleWeb.TaskSupervisor, fn ->
      try do
        packet = List.last(packets)
        if packet != nil do
          IO.inspect "PROCESSING PACKET FROM ETL ERROR WORKER..."
          parsed_packet = packet |> Jason.decode!() |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

          org = Organizations.get_organization!(parsed_packet.organization_id)
          org_attrs = %{
            "dc_balance" => Enum.max([org.dc_balance - parsed_packet.dc_used, 0]),
            "total_dc" => org.total_dc + parsed_packet.dc_used,
            "total_packets" => org.total_packets + 1
          }

          with {:ok, updated_org} <- Organizations.update_organization!(org, org_attrs) do
            ConsoleWeb.Monitor.remove_from_packets_error_state()
            if org.dc_balance - parsed_packet.dc_used <= 0 do
              net_id_values = NetIds.get_all_for_organization(org.id) |> Enum.map(fn n -> n.value end)
              ConsoleWeb.Endpoint.broadcast("net_id:all", "net_id:all:stop_purchasing", %{ net_ids: net_id_values})
            end
            ConsoleWeb.DataCreditController.check_org_dc_balance(updated_org, org.dc_balance)
          end
        end
      rescue
        error ->
          ConsoleWeb.Monitor.remove_from_packets_error_state()
          Appsignal.send_error(error, "Failed to process in ETL Error Worker", __STACKTRACE__)
      end
    end)
    |> Task.await(:infinity)

    schedule_packets_error_etl(1)
    {:noreply, state}
  end

  defp schedule_packets_error_etl(wait_time) do
    Process.send_after(self(), :run_packets_error_etl, wait_time)
  end
end
