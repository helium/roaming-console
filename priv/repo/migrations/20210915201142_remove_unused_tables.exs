defmodule Console.Repo.Migrations.RemoveUnusedTables do
  use Ecto.Migration

  def change do
    drop table(:events)
    drop table(:devices_labels)
    drop table(:channels_labels)
    drop table(:channels)
    drop table(:devices)
    drop table(:gateways)
    drop table(:hardware_identifiers)
    drop table(:labels)
    drop table(:twofactors)
  end
end
