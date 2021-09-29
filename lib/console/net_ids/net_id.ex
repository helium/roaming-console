defmodule Console.NetIds.NetId do
  use Ecto.Schema
  import Ecto.Changeset

  alias Console.Organizations.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "net_ids" do
    field :value, :string

    belongs_to :organization, Organization
    timestamps()
  end

  @doc false
  def changeset(net_id, attrs) do
    net_id
    |> cast(attrs, [:value, :organization_id])
    |> validate_required([:value, :organization_id])
    |> unique_constraint(:value, name: :net_ids_value_index, message: "That Net ID has already been taken.")
  end
end
