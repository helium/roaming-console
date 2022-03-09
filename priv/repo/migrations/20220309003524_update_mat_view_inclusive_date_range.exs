defmodule Console.Repo.Migrations.UpdateMatViewInclusiveDateRange do
  use Ecto.Migration

  def up do
    execute """
    DROP MATERIALIZED VIEW packets_view;
    CREATE MATERIALIZED VIEW packets_view AS
      SELECT stats30d.organization_id, packets_30d, dc_30d from
      (
        SELECT organization_id, COUNT(id) AS packets_30d, SUM(dc_used) AS dc_30d FROM packets
        WHERE reported_at_epoch >= CAST(EXTRACT(epoch FROM NOW()) * 1000 - 2592000000 AS BIGINT) AND reported_at_epoch <= CAST(EXTRACT(epoch FROM NOW()) * 1000 - 86400000 AS BIGINT) GROUP BY organization_id
      ) stats30d
    ;
    """
  end

  def down do
    execute """
    DROP MATERIALIZED VIEW packets_view;
    CREATE MATERIALIZED VIEW packets_view AS
      SELECT stats30d.organization_id, packets_30d, dc_30d from
      (
        SELECT organization_id, COUNT(id) AS packets_30d, SUM(dc_used) AS dc_30d FROM packets
        WHERE reported_at_epoch > CAST(EXTRACT(epoch FROM NOW()) * 1000 - 2592000000 AS BIGINT) AND reported_at_epoch < CAST(EXTRACT(epoch FROM NOW()) * 1000 - 86400000 AS BIGINT) GROUP BY organization_id
      ) stats30d
    ;
    """
  end
end
