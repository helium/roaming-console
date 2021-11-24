defmodule Console.Repo.Migrations.AddTypeToPackets do
  use Ecto.Migration

  def change do
    alter table(:packets) do
      add :type, :string, null: false
    end
  end
end
