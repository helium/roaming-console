defmodule Console.Repo.Migrations.RemoveAlertsTables do
  use Ecto.Migration

  def change do  
    drop table(:alerts)
  end
end
