defmodule Console.Repo.Migrations.AddOrgFields do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :total_dc, :integer, null: false, default: 0
      add :total_packets, :integer, null: false, default: 0
    end
  end
end
