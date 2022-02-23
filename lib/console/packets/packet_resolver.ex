defmodule Console.Packets.PacketResolver do
  alias Console.Packets

  def get_packets(_, %{context: %{current_organization: current_organization}}) do
    current_unix = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    unix1d = current_unix - 86400000
    packets = Packets.get_packets_per_netid(current_organization.id, unix1d)

    {:ok, packets}
  end
end