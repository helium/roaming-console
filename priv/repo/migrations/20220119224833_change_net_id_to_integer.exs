defmodule Console.Repo.Migrations.ChangeNetIdToInteger do
  use Ecto.Migration

  def change do
    alter table("net_ids") do
      modify :value, :integer, null: false
    end

    alter table("packets") do
      modify :net_id, :integer, null: false
    end
  end
end
