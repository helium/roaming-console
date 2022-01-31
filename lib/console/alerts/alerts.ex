defmodule Console.Alerts do
  import Ecto.Query, warn: false
  alias Console.Repo

  alias Console.Alerts.Alert
  alias Console.Organizations.Organization

  def get_alert(organization) do
     Repo.get_by(Alert, [organization_id: organization.id])
  end

  def create_alert(attrs \\ %{}, %Organization{} = organization) do
    attrs = Map.merge(attrs, %{"organization_id" => organization.id})

    %Alert{}
    |> Alert.changeset(attrs)
    |> Repo.insert()
  end

  def update_alert(attrs \\ %{}, %Alert{} = alert) do
    alert
    |> Alert.changeset(attrs)
    |> Repo.update()
  end
end
