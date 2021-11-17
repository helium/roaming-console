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

  def handle_in(
    "router:new_packet",
    %{
      "dc_used" => _,
      "packet_size" => _,
      "organization_id" => _,
      "reported_at_epoch" => _,
      "packet_hash" => _
    } = packet_attrs,
    socket
  ) do
    {:ok, _} = Packets.create_packet(packet_attrs)

    # Respond with something else if fails?
    {:reply, :ok, socket}
  end
end
