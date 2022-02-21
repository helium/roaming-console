defmodule Console.Repo.Migrations.RemoveTeamTable do
  use Ecto.Migration

  def change do
    drop_if_exists table(:teams)
  end
end
