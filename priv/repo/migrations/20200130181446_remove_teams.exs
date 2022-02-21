defmodule Console.Repo.Migrations.RemoveTeams do
  use Ecto.Migration

  def change do
    alter table(:devices) do
      remove :team_id
    end

    alter table(:gateways) do
      remove :team_id
    end
  end
end
