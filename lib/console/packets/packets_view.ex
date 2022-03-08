defmodule Console.Packets.PacketsView do
  use Ecto.Schema

  @primary_key {:organization_id, :binary_id, []}
  schema "packets_view" do
    field :packets_30d, :integer
    field :dc_30d, :integer
  end
end