defmodule Console.Repo.Migrations.MoveActiveToConfigLevel do
  use Ecto.Migration

  def up do
    net_ids = Ecto.Adapters.SQL.query!(Console.Repo, """
      SELECT id, active, config FROM net_ids;
    """).rows

    Enum.each(net_ids, fn n ->
      config = Enum.map(Enum.filter(Enum.at(n, 2), fn nc -> map_size(nc) != 0 end), fn net_id_config ->
        if map_size(net_id_config) != 0 do
          Map.put_new(net_id_config, "active", Enum.at(n, 1)) |> Map.put_new("config_id", Ecto.UUID.generate())
        else
          net_id_config
        end
      end)

      Ecto.Adapters.SQL.query!(Console.Repo, """
        UPDATE net_ids SET config = $1 WHERE id = $2;
      """, [config, Enum.at(n, 0)])
    end)

    Ecto.Adapters.SQL.query!(Console.Repo, """
      ALTER TABLE net_ids DROP COLUMN active;
    """)
  end

  def down do
    Ecto.Adapters.SQL.query!(Console.Repo, """
      ALTER TABLE net_ids ADD COLUMN active BOOLEAN NOT NULL DEFAULT true;
    """)

    net_ids = Ecto.Adapters.SQL.query!(Console.Repo, """
      SELECT id, active, config FROM net_ids;
    """).rows

    Enum.each(net_ids, fn n ->
      active = Enum.any?(Enum.at(n, 2), fn c -> c["active"] end)

      config = Enum.map(Enum.at(n, 2), fn config ->
        {_, updated_config} = Map.pop(config, "active")
        {_, updated_config} = Map.pop(updated_config, "config_id")
        updated_config
      end)

      Ecto.Adapters.SQL.query!(Console.Repo, """
        UPDATE net_ids SET active = $1, config = $2 WHERE id = $3;
      """, [active, config, Enum.at(n, 0)])
    end)
  end
end
