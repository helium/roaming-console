defmodule Console.EtlWorker do
  use GenServer
  alias Console.Organizations
  alias Console.NetIds
  alias Console.Repo

  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(_opts) do
    schedule_packets_etl(10)
    {:ok, %{}}
  end

  def handle_info(:run_packets_etl, state) do
    packets = ConsoleWeb.Monitor.get_packets_state()
    delivery_tags = Enum.map(packets, fn e -> elem(e, 0) end)

    Task.Supervisor.async_nolink(ConsoleWeb.TaskSupervisor, fn ->
      try do
        parsed_packets = Enum.map(packets, fn e -> elem(e, 1) |> Jason.decode!() end)

        if length(parsed_packets) > 0 do      
          organization_updates_map = generate_organization_updates_map(parsed_packets)

          organizations_to_update =
            organization_updates_map
            |> Map.keys()
            |> Organizations.get_organizations_in_list()
          
          result =
            Ecto.Multi.new()
            |> Ecto.Multi.run(:org_updates, fn _repo, _ ->
              Enum.each(organizations_to_update, fn org ->
                org_attrs = %{
                  "dc_balance" => Enum.max([org.dc_balance - organization_updates_map[org.id]["dc_used"], 0]),
                }
                
                net_id_values = NetIds.get_all_for_organization(org.id) |> Enum.map(fn n -> n.value end)
                if org.dc_balance - organization_updates_map[org.id]["dc_used"] <= 0 do
                  ConsoleWeb.Endpoint.broadcast("net_id:all", "net_id:all:stop_purchasing", %{ net_ids: net_id_values})
                end

                Organizations.update_organization(org, org_attrs)
              end)
              {:ok, "success"}
            end)
            |> Repo.transaction()
          
          with {:ok, _} <- result do
            ConsoleWeb.MessageQueueConsumer.ack(delivery_tags)
            ConsoleWeb.Monitor.remove_from_packets_state(length(packets))
          end
        end
      rescue
        error ->
          ConsoleWeb.MessageQueueConsumer.reject(delivery_tags)
          ConsoleWeb.Monitor.remove_from_packets_state(length(packets))
          Appsignal.send_error(error, "Failed to process in ETL Worker", ["etl_worker"])
      end
    end)
    |> Task.await(:infinity)

    schedule_packets_etl(1)
    {:noreply, state}
  end

  defp schedule_packets_etl(wait_time) do
    Process.send_after(self(), :run_packets_etl, wait_time)
  end

  defp generate_organization_updates_map(parsed_packets) do
    parsed_packets
    |> Enum.reduce(%{}, fn packet, acc ->
      if packet["dc_used"] > 0 do
        update_attrs =
          case acc[packet["organization_id"]] do
            nil ->
              %{
                "dc_used" => packet["dc_used"],
              }
            _ ->
              %{
                "dc_used" => packet["dc_used"] + acc[packet["organization_id"]]["dc_used"],
              }
          end

        Map.merge(acc, %{ packet["organization_id"] => update_attrs })
      else
        acc
      end
    end)
  end
end