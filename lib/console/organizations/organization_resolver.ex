defmodule Console.Organizations.OrganizationResolver do
  import Ecto.Query, warn: false
  alias Console.Repo
  alias Console.Organizations
  alias Console.Packets

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
    organization = Organizations.get_organization!(current_user, id) |> Repo.preload([:net_ids])

    stats_view =
      case Packets.get_count_view_for_org(organization.id) do
        nil ->
          %{}
        result ->
          result
          |> Map.from_struct
          |> Enum.filter(fn {_, v} -> v != nil end)
          |> Enum.into(%{})
      end

    organization = organization
      |> Map.put(:packets_last_30d, Map.get(stats_view, :packets_30d, 0))
      |> Map.put(:dc_last_30d, Map.get(stats_view, :dc_30d, 0))
    
    {:ok, organization}
  end

  def all(_, %{context: %{current_user: current_user}}) do
    organizations =
      Organizations.get_organizations(current_user)

    {:ok, organizations}
  end
end
