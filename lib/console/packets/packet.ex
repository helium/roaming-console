defmodule Console.Packets.Packet do
  use Ecto.Schema
  import Ecto.Changeset

  alias Console.Organizations.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "packets" do
    field :dc_used, :integer
    field :packet_size, :integer
    field :reported_at_epoch, :integer
    field :packet_hash, :string
    field :type, :string
    field :serial, :integer
    field :net_id, :integer

    belongs_to :organization, Organization
    timestamps()
  end

  @doc false
  def changeset(packet, attrs) do
    packet
    |> cast(attrs, [
      :dc_used,
      :packet_size,
      :organization_id,
      :reported_at_epoch,
      :packet_hash,
      :type,
      :net_id
    ])
  end
end
