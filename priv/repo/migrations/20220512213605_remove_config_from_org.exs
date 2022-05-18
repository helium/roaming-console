defmodule Console.Repo.Migrations.RemoveConfigFromOrg do
  use Ecto.Migration

  def up do
    alter table(:organizations) do
      remove :address
      remove :join_credentials
      remove :disable_pull_data
      remove :multi_buy
      remove :port
    end
  end

  def down do
    alter table(:organizations) do
      add :address, :string
      add :join_credentials, :string
      add :port, :integer
      add :multi_buy, :integer
      add :disable_pull_data, :boolean, null: false, default: false
    end
  end
end
