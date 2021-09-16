defmodule Console.Repo.Migrations.RemoveAlertsTables do
  use Ecto.Migration

  def change do
    drop table(:alert_nodes)
    drop table(:alerts)
  end
end
