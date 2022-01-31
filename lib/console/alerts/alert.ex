defmodule Console.Alerts.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  alias Console.Organizations.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "alerts" do
    field :config, :map

    belongs_to :organization, Organization
    timestamps()
  end

  @doc false
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:config, :organization_id])
    |> validate_required([:config, :organization_id])
    |> unique_constraint(:organization_id, name: :alerts_organization_id_index, message: "Alert config already exists for this organization.")
  end
end
