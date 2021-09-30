defmodule Console.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  alias Console.Organizations.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notifications" do
    field :config, :map

    belongs_to :organization, Organization
    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:config, :organization_id])
    |> validate_required([:config, :organization_id])
    |> unique_constraint(:organization_id, name: :notifications_organization_id_index, message: "Notification config already exists for this organization.")
  end
end
