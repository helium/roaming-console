defmodule Console.Repo.Migrations.MoveConfigs do
  use Ecto.Migration

  def cast_organization(record) do
    {:ok, organization_id} = Ecto.UUID.load(Enum.at(record, 0))

    %{
      id: organization_id,
      address: Enum.at(record, 1),
      join_credentials: Enum.at(record, 2),
      port: Enum.at(record, 3),
      multi_buy: Enum.at(record, 4),
      disable_pull_data: Enum.at(record, 5),
    }
  end

  def cast_net_id(record) do
    {:ok, organization_id} = Ecto.UUID.load(Enum.at(record, 1))

    %{
      id: Enum.at(record, 0),
      organization_id: organization_id
    }
  end

  def change do
    organizations = Ecto.Adapters.SQL.query!(Console.Repo, """
      SELECT id, address, join_credentials, port, multi_buy, disable_pull_data FROM organizations;
    """).rows |> Enum.map(fn o -> cast_organization(o) end)

    net_ids = Ecto.Adapters.SQL.query!(Console.Repo, """
      SELECT id, organization_id FROM net_ids;
    """).rows |> Enum.map(fn n -> cast_net_id(n) end)

    Enum.each(net_ids, fn n ->
      org = Enum.find(organizations, fn o -> o.id == n.organization_id end)
      joins = case org.join_credentials do
        nil -> []
        _ -> Jason.decode!(org.join_credentials)
      end

      config = %{
        protocol: "udp",
        address: org.address,
        join_credentials: joins,
        port: org.port,
        multi_buy: org.multi_buy,
        disable_pull_data: org.disable_pull_data
      }
      Ecto.Adapters.SQL.query!(Console.Repo, """
        UPDATE net_ids SET config = $1 WHERE id = $2;
      """, [config, n.id])
    end)
  end
end
