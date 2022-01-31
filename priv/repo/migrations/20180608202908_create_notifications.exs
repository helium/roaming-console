defmodule Console.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add :team_id, references(:teams)
      add :title, :string, null: false
      add :body, :string
      add :url, :string
      add :category, :string

      timestamps()
    end

    create table(:alert_views) do
      add :alert_id, references(:alerts)
      add :membership_id, references(:memberships)

      timestamps()
    end

    create unique_index(:alert_views, [:alert_id, :membership_id])
  end
end
