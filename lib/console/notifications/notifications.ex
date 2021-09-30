defmodule Console.Notifications do
  import Ecto.Query, warn: false
  alias Console.Repo

  alias Console.Notifications.Notification
  alias Console.Organizations.Organization

  def get_notification(organization) do
     Repo.get_by(Notification, [organization_id: organization.id])
  end

  def create_notification(attrs \\ %{}, %Organization{} = organization) do
    attrs = Map.merge(attrs, %{"organization_id" => organization.id})

    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  def update_notification(attrs \\ %{}, %Notification{} = notification) do
    notification
    |> Notification.changeset(attrs)
    |> Repo.update()
  end
end
