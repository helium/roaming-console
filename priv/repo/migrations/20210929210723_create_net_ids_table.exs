defmodule Console.Repo.Migrations.CreateNetIdsTable do
  use Ecto.Migration

  def change do
    create table(:net_ids) do
      add :value, :string, null: false
      add :organization_id, references(:organizations), null: false, on_delete: :delete_all

      timestamps()
    end

    create unique_index(:net_ids, [:value])
  end
end
