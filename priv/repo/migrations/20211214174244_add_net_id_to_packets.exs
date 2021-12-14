defmodule Console.Repo.Migrations.AddNetIdToPackets do
  use Ecto.Migration

  def change do
    alter table(:packets) do
      add :net_id, :string, null: false
    end

    create index(:packets, [:net_id])
  end
end
