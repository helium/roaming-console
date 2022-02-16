defmodule Console.Alerts do
  import Ecto.Query, warn: false
  alias Console.Repo

  alias Console.Alerts.Alert
  alias Console.Organizations.Organization
  alias Console.Organizations

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

  def get_alert_recipient_emails(%Organization{} = organization, recipient_type) do
    roles = case recipient_type do
      "admin" -> ["admin"]
      "manager" -> ["manager"]
      "read" -> ["read"]
      "all" -> ["admin", "manager", "read"]
    end

    Organizations.get_memberships_by_organization_and_role(organization.id, roles) |> Enum.map(fn (member) -> member.email end)
  end
end
