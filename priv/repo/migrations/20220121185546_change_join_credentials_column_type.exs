defmodule Console.Repo.Migrations.ChangeJoinCredentialsColumnType do
  use Ecto.Migration

  def change do
    alter table("organizations") do
      modify :join_credentials, :text, null: true
    end
  end
end
