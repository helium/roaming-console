defmodule Console.NetIds do
  import Ecto.Query, warn: false
  alias Console.Repo

  alias Console.NetIds.NetId
  alias Console.Organizations.Organization
  alias Console.Organizations

  def create_net_id!(attrs \\ %{}, %Organization{} = organization) do
    %NetId{}
    |> NetId.changeset(attrs)
    |> Repo.insert!()
  end
end
