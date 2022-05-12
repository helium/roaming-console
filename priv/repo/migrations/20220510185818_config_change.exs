defmodule Console.Repo.Migrations.ConfigChange do
  use Ecto.Migration

  def change do
    alter table(:net_ids) do
      add :config, :map, default: %{}, null: false
    end
  end
end
