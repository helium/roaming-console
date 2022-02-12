defmodule Console.EtlWorker do
  use GenServer
  alias Console.Organizations
  alias Console.NetIds
  alias Console.Repo

  def start_link(initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(_opts) do
    if Application.get_env(:console, :use_amqp_events) do
      schedule_events_etl(10)
    end
    {:ok, %{}}
  end

  def handle_info(:run_events_etl, state) do
    events = ConsoleWeb.Monitor.get_events_state()
    delivery_tags = Enum.map(events, fn e -> elem(e, 0) end)

    Task.Supervisor.async_nolink(ConsoleWeb.TaskSupervisor, fn ->
      try do
        parsed_events = Enum.map(events, fn e -> elem(e, 1) |> Jason.decode!() end)

        if length(parsed_events) > 0 do      
          organization_updates_map = generate_organization_updates_map(parsed_events)

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
            ConsoleWeb.Monitor.remove_from_events_state(length(events))
          end
        end
      rescue
        error ->
          ConsoleWeb.MessageQueueConsumer.reject(delivery_tags)
          ConsoleWeb.Monitor.remove_from_events_state(length(events))
          Appsignal.send_error(error, "Failed to process in ETL Worker", ["etl_worker"])
      end
    end)
    |> Task.await(:infinity)

    schedule_events_etl(1)
    {:noreply, state}
  end

  defp schedule_events_etl(wait_time) do
    Process.send_after(self(), :run_events_etl, wait_time)
  end

  defp generate_organization_updates_map(parsed_events) do
    parsed_events
    |> Enum.reduce(%{}, fn event, acc ->
      if event["dc_used"] > 0 do
        update_attrs =
          case acc[event["organization_id"]] do
            nil ->
              %{
                "dc_used" => event["dc_used"],
              }
            _ ->
              %{
                "dc_used" => event["dc_used"] + acc[event["organization_id"]]["dc_used"],
              }
          end

        Map.merge(acc, %{ event["organization_id"] => update_attrs })
      else
        acc
      end
    end)
  end
end