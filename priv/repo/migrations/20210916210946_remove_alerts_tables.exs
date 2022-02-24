defmodule Console.Repo.Migrations.RemoveAlertsTables do
  use Ecto.Migration

  def change do
    drop_if_exists table(:alert_views)
    drop_if_exists table(:alerts), mode: :cascade
  end
end
