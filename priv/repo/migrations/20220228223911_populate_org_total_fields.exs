defmodule Console.Repo.Migrations.PopulateOrgTotalFields do
  use Ecto.Migration

  def up do
    results = Ecto.Adapters.SQL.query!(Console.Repo, """
      SELECT sum(dc_used), count(*), organization_id FROM packets GROUP BY organization_id;
    """, [], timeout: :infinity).rows

    Enum.each(results, fn row ->
      Ecto.Adapters.SQL.query!(Console.Repo, """
        UPDATE organizations SET total_dc = $1, total_packets = $2 WHERE id = $3;
      """, [Enum.at(row, 0), Enum.at(row, 1), Enum.at(row, 2)])
    end)
  end

  def down do
  end
end
