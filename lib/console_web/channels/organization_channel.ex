defmodule ConsoleWeb.OrganizationChannel do
  use Phoenix.Channel
  alias Console.Packets

  def join("organization:all", _message, socket) do
    {:ok, socket}
  end

  def handle_in("router:address", %{"address" => router_address}, socket) do
    router_address
    |> to_string()
    |> ConsoleWeb.Monitor.update_router_address()

    {:reply, :ok, socket}
  end

  def handle_in("router:new_packet", packet, socket) do
    packet_attrs = %{
      "dc_used" => packet["dc_used"]["used"],
      "packet_size" => packet["packet_size"],
      "organization_id" => packet["organization_id"],
      "reported_at_epoch" => packet["reported_at_epoch"],
      "packet_hash" => packet["packet_hash"],
      "type" => packet["type"]
    }
    {:ok, _} = Packets.create_packet(packet_attrs)

    # Respond with something else if fails?
    {:reply, :ok, socket}
  end
end
