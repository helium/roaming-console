defmodule Console.Packets do
  import Ecto.Query, warn: false
  alias Console.Repo

  alias Console.Packets.Packet
  alias Console.Packets.PacketsView

  def create_packet(attrs \\ %{}) do
    %Packet{}
    |> Packet.changeset(attrs)
    |> Repo.insert()
  end

  def get_packets_per_netid(organization_id, epoch_since, current_epoch) do
    query = from p in Packet,
      select: %{reported_at_epoch: p.reported_at_epoch, net_id: p.net_id, dc_used: p.dc_used},
      where: p.organization_id == ^organization_id and p.reported_at_epoch > ^epoch_since and p.reported_at_epoch < ^current_epoch
    Repo.all(query)
  end

  def get_count_view_for_org(id) do
    Repo.get(PacketsView, id)
  end
end
