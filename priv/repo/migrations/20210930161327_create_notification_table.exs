defmodule Console.Repo.Migrations.CreateNotificationTable do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :config, :map, default: %{}, null: false
      add :organization_id, references(:organizations), null: false, on_delete: :delete_all

      timestamps()
    end

    create index(:net_ids, [:organization_id])
    create unique_index(:notifications, [:organization_id])
  end
end
