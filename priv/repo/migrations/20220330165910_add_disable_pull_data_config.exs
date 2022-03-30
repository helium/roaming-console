defmodule Console.Repo.Migrations.AddDisablePullDataConfig do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :disable_pull_data, :boolean, null: false, default: false
    end
  end
end
