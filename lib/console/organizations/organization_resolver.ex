defmodule Console.Organizations.OrganizationResolver do
  import Ecto.Query, warn: false
  alias Console.Repo
  alias Console.Organizations
  alias Console.Packets.Packet

  def paginate(%{page: page, page_size: page_size}, %{context: %{current_user: current_user}}) do
    organizations =
      case current_user.super do
        true ->
          Organization |> Repo.paginate(page: page, page_size: page_size)
        _ ->
          orgs = Organizations.get_organizations(current_user)
          %{
            entries: orgs,
          }
      end

    {:ok, Map.put(organizations, :entries, organizations.entries)}
  end

  def find(%{id: id}, %{context: %{current_user: current_user}}) do
    organization = Organizations.get_organization!(current_user, id)

    query = from p in Packet,
      select: %{
        total_dc_used: sum(p.dc_used),
        total_packets_sent: count()
      },
      where: p.organization_id == ^id

    result = Repo.one!(query)

    organization =
      Map.put(organization, :total_dc_used, result.total_dc_used)
      |> Map.put(:total_packets_sent, result.total_packets_sent)
    {:ok, organization}
  end

  def all(_, %{context: %{current_user: current_user}}) do
    organizations =
      Organizations.get_organizations(current_user)

    {:ok, organizations}
  end
end
