defmodule ConsoleWeb.OrganizationChannel do
  use Phoenix.Channel
  alias Console.Packets
  alias Console.NetIds

  def join("organization:all", _message, socket) do
    {:ok, socket}
  end

  def handle_in("packet_purchaser:address", %{"address" => packet_purchaser_address}, socket) do
    packet_purchaser_address
    |> to_string()
    |> ConsoleWeb.Monitor.update_packet_purchaser_address()

    {:noreply, socket}
  end

  def handle_in("packet_purchaser:get_config", _message, socket) do
    ConsoleWeb.OrganizationController.broadcast_packet_purchaser_all_org_config()

    {:noreply, socket}
  end

  def handle_in("packet_purchaser:get_org_balances", _message, socket) do
    ConsoleWeb.OrganizationController.broadcast_packet_purchaser_all_org_balance()

    {:noreply, socket}
  end

  def handle_in("packet_purchaser:new_packet", packet, socket) do
    net_id = NetIds.get_net_id(packet["net_id"])
    IO.inspect packet
    IO.puts net_id

    if net_id == nil do
      {:reply, {:error, "Net Id does not associate with an organization"}, socket}
    else
      packet_attrs = %{
        "dc_used" => packet["dc_used"],
        "packet_size" => packet["packet_size"],
        "organization_id" => net_id.organization_id,
        "reported_at_epoch" => packet["reported_at_epoch"],
        "packet_hash" => packet["packet_hash"],
        "type" => packet["type"],
        "net_id" => packet["net_id"],
      }

      case Packets.create_packet(packet_attrs) do
        {:ok, _} ->
          {:noreply, socket}
        _ ->
          {:reply, {:error, "Failed to add packet to database"}, socket}
      end
    end
  end
end
