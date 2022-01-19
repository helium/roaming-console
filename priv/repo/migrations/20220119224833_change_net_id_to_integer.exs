defmodule Console.Repo.Migrations.ChangeNetIdToInteger do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE net_ids ALTER COLUMN value TYPE integer USING (value::integer)"
    execute "ALTER TABLE packets ALTER COLUMN net_id TYPE integer USING (net_id::integer)" 
  end
end
