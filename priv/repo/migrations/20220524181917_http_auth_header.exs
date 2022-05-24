defmodule Console.Repo.Migrations.HttpAuthHeader do
  use Ecto.Migration

  def change do
    alter table(:net_ids) do
      add :http_headers, :binary
    end
  end
end
