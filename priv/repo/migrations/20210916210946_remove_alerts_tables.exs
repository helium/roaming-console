defmodule Console.Repo.Migrations.RemoveAlertsTables do
  use Ecto.Migration

  def change do
    drop table(:alert_views)
    drop table(:alerts)
  end
end
