defmodule Console.Packets.PacketResolver do
  alias Console.Packets

  def get_packets(_, %{context: %{current_organization: current_organization}}) do
    current_unix = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    unix1d = current_unix - 86400000
    packets = Packets.get_packets_per_netid(current_organization.id, unix1d, current_unix)

    {:ok, process_for_chart(packets)}
  end

  defp process_for_chart(packets) do
    %{ packets_per_hour: Enum.reduce(packets, %{}, fn packet, acc ->
      key = trunc(Float.ceil(((DateTime.utc_now() |> DateTime.to_unix(:millisecond)) - packet.reported_at_epoch) / 1000 / 3600))
      if acc[key] do
        if acc[key][packet.net_id] do
          Map.put(acc, key, Map.put(acc[key], packet.net_id, acc[key][packet.net_id] + 1))
        else
          Map.put(acc, key, Map.put(acc[key], packet.net_id, 1))
        end
      else
        Map.put(acc, key, %{ packet.net_id => 1 })
      end
    end)}
  end
end