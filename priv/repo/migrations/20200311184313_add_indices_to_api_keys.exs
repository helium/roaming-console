defmodule Console.Repo.Migrations.AddIndicesToApiKeys do
  use Ecto.Migration

  def change do
    create index(:api_keys, [:key])
    create unique_index(:api_keys, [:name, :organization_id])
  end
end
