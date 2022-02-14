defmodule ConsoleWeb.PacketPurchaser.PacketController do
  use ConsoleWeb, :controller

  alias Console.Packets
    alias Console.NetIds

  action_fallback(ConsoleWeb.FallbackController)

  def send_packerooni(conn, _) do # TODO delete this, only added for easier testing
    net_id = NetIds.get_net_id(9)

    if net_id == nil do
      {:error}
    else
      packet_attrs = %{
        "dc_used" => 4,
        "packet_size" => 1,
        "organization_id" => net_id.organization_id,
        "reported_at_epoch" => 1644863419389,
        "packet_hash" => "1234",
        "type" => "unknown",
        "net_id" => 9,
      }

      with {:ok, new_packet} <- Packets.create_packet(packet_attrs) do
        ConsoleWeb.MessageQueuePublisher.publish(Jason.encode!(%{
          "id" => new_packet.id,
          "dc_used" => 4,
          "net_id" => 9,
          "organization_id" => net_id.organization_id,
        }))

        conn
        |> put_resp_header("message", "yay")
        |> send_resp(:no_content, "")
      else
        _ ->
          {:error}
      end
    end
  end
end