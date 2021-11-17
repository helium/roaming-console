defmodule Console.Packets do
  import Ecto.Query, warn: false
  alias Console.Repo

  alias Console.Packets.Packet

  def create_packet(attrs \\ %{}) do
    %Packet{}
    |> Packet.changeset(attrs)
    |> Repo.insert()
  end
end
