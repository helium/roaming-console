defmodule ConsoleWeb.PacketPurchaser.PacketController do
  use ConsoleWeb, :controller

  alias Console.Packets
    alias Console.NetIds

  action_fallback(ConsoleWeb.FallbackController)

  @doc """
  Since Packet Purchaser uses a web socket to send packets to Roaming Console,
  this endpoint is purely for internal testing and protected as a PP API route.
  NOTE: Must have an existing net_id associated to an existing org.
  """
  def test_send_packet(conn, %{ "net_id" => net_id }) do
    net_id = NetIds.get_net_id(net_id)
    current_unix = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    if net_id == nil do
      {:error}
    else
      packet_attrs = %{
        "dc_used" => 4,
        "packet_size" => 1,
        "organization_id" => net_id.organization_id,
        "reported_at_epoch" => current_unix,
        "packet_hash" => "1234",
        "type" => "unknown",
        "net_id" => 9,
      }

      with {:ok, new_packet} <- Packets.create_packet(packet_attrs) do
        ConsoleWeb.MessageQueuePublisher.publish(Jason.encode!(%{
          "id" => new_packet.id,
          "dc_used" => new_packet.dc_used,
          "net_id" => new_packet.net_id,
          "organization_id" => net_id.organization_id,
        }))

        conn
        |> send_resp(:no_content, "")
      else
        _ ->
          {:error}
      end
    end
  end
end 