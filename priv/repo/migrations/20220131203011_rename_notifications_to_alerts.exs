defmodule Console.Repo.Migrations.RenameNotificationsToAlerts do
  use Ecto.Migration

  def change do
    drop table("notifications")
    create table(:alerts) do
      add :config, :map, default: %{}, null: false
      add :organization_id, references(:organizations), null: false, on_delete: :delete_all

      timestamps()
    end
    
    create unique_index(:alerts, [:organization_id])
  end
end
