defmodule Console.Repo.Migrations.AddSettingsToOrg do
  use Ecto.Migration

  def change do
    alter table(:organizations) do
      add :address, :string
      add :join_credentials, :string
      add :port, :integer
      add :multi_buy, :integer
    end
  end
end
