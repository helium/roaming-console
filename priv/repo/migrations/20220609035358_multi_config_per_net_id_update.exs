defmodule Console.Repo.Migrations.MultiConfigPerNetIdUpdate do
  use Ecto.Migration
  alias Console.NetIds

  def up do
    Ecto.Adapters.SQL.query!(Console.Repo, """
      ALTER TABLE net_ids ALTER COLUMN config DROP DEFAULT;
    """)

     Ecto.Adapters.SQL.query!(Console.Repo, """
       ALTER TABLE net_ids ALTER COLUMN config TYPE jsonb[] USING ARRAY[config]::jsonb[];
    """)

    Ecto.Adapters.SQL.query!(Console.Repo, """
      ALTER TABLE net_ids ALTER COLUMN config SET DEFAULT ARRAY[]::jsonb[];
    """)
  end

  def down do
    Ecto.Adapters.SQL.query!(Console.Repo, """
      alter table net_ids alter column config drop not null;
    """)

    Ecto.Adapters.SQL.query!(Console.Repo, """
      ALTER TABLE net_ids ALTER COLUMN config DROP DEFAULT;
    """)

    Ecto.Adapters.SQL.query!(Console.Repo, """
    create or replace function jsonb_array_to_jsonb(jsonb[])
    returns jsonb language sql as $$
        select jsonb_object_agg(key, value)
        from unnest($1), jsonb_each(unnest)
    $$;
    """)

    Ecto.Adapters.SQL.query!(Console.Repo, """
      ALTER TABLE net_ids ALTER COLUMN config TYPE jsonb USING jsonb_array_to_jsonb(config);
    """)

    Ecto.Adapters.SQL.query!(Console.Repo, """
      ALTER TABLE net_ids ALTER COLUMN config SET DEFAULT '{}';
    """)

    Ecto.Adapters.SQL.query!(Console.Repo, """
      UPDATE net_ids SET config = '{}' WHERE config IS NULL;
    """)

    Ecto.Adapters.SQL.query!(Console.Repo, """
      ALTER TABLE net_ids ALTER COLUMN config SET NOT NULL;
    """)
  end
end
