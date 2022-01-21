defmodule Console.NetIds do
  import Ecto.Query, warn: false
  alias Console.Repo

  alias Console.NetIds.NetId
  alias Console.Organizations.Organization

  def get_net_id(id) do
    Repo.get_by(NetId, [value: id])
  end

  def create_net_id!(attrs \\ %{}, %Organization{} = organization) do
    attrs = Map.merge(attrs, %{"organization_id" => organization.id})

    %NetId{}
    |> NetId.changeset(attrs)
    |> Repo.insert!()
  end

  def get_all_for_organization(organization_id) do
    query = from n in NetId,
      select: %{value: n.value},
      where: n.organization_id == ^organization_id
    Repo.all(query)
  end
end
