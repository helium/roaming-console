defmodule Console.Packets.PacketResolver do
  alias Console.Repo
  import Ecto.Query

  def get_packets(_, %{context: %{current_organization: current_organization}}) do
    current_unix = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    unix1d = current_unix - 86400000
    {:ok, organization_id} = Ecto.UUID.dump(current_organization.id)

    sql = """
      SELECT net_id, reported_at_epoch
      FROM packets
      WHERE organization_id = $1 AND reported_at_epoch > $2
      ORDER BY reported_at_epoch DESC
    """
    result = Ecto.Adapters.SQL.query!(Console.Repo, sql, [organization_id, unix1d])
    rows =
      result.rows
      |> Enum.map(fn r ->
        %{ net_id: Enum.at(r, 0), reported_at_epoch: Enum.at(r, 1) }
      end)

    {:ok, rows}
  end
end