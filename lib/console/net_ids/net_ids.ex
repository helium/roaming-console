defmodule Console.NetIds do
  import Ecto.Query, warn: false
  alias Console.Repo
  alias Console.Auth.User
  alias Console.Organizations.Membership

  alias Console.NetIds.NetId
  alias Console.Organizations.Organization

  def get_net_id(id) do
    Repo.get_by(NetId, [value: id])
  end

  def get_net_id!(%User{} = current_user, id) do
    if current_user.super do
      Repo.get!(NetId, id)
    else
      query = from n in NetId,
        join: m in Membership, on: m.organization_id == n.organization_id,
        where: m.user_id == ^current_user.id and n.id == ^id
      Repo.one!(query)
    end
  end

  # def create_net_id!(attrs \\ %{}, %Organization{} = organization) do
  #   attrs = Map.merge(attrs, %{"organization_id" => organization.id})

  #   %NetId{}
  #   |> NetId.changeset(attrs)
  #   |> Repo.insert!()
  # end

  def get_all_for_organization(organization_id) do
    query = from n in NetId,
      select: %{value: n.value, config: n.config, active: n.active},
      where: n.organization_id == ^organization_id
    Repo.all(query)
  end

  def update_net_id(%NetId{} = net_id, attrs) do
    net_id
    |> NetId.update_changeset(attrs)
    |> Repo.update()
  end
end
