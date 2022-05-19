defmodule Console.Repo.Migrations.ActiveNetId do
  use Ecto.Migration

  def change do
    alter table(:net_ids) do
      add :active, :boolean, default: true, null: false
    end
  end
end
