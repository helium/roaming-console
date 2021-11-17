defmodule Console.Repo.Migrations.CreatePacketsTable do
  use Ecto.Migration

  def change do
    create table(:packets) do
      add :dc_used, :integer, null: false
      add :packet_size, :integer, null: false
      add :reported_at_epoch, :bigint, null: false
      add :packet_hash, :string
      add :organization_id, references(:organizations), null: false, on_delete: :delete_all
      add :serial, :serial

      timestamps()
    end

    create index(:packets, [:organization_id])
    create index(:packets, [:organization_id, :reported_at_epoch])
    create index(:packets, [:serial])
  end
end
