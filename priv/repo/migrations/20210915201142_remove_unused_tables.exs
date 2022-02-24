defmodule Console.Repo.Migrations.RemoveUnusedTables do
  use Ecto.Migration

  def change do
    drop_if_exists table(:events)
    drop_if_exists table(:devices_labels)
    drop_if_exists table(:channels_labels)
    drop_if_exists table(:flows)
    drop_if_exists table(:channels)
    drop_if_exists table(:devices), mode: :cascade
    drop_if_exists table(:gateways)
    drop_if_exists table(:hardware_identifiers)
    drop_if_exists table(:labels)
    drop_if_exists table(:twofactors)
  end
end
