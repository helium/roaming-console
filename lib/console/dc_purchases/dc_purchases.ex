defmodule Console.DcPurchases do
  import Ecto.Query, warn: false
  alias Console.Repo

  alias Console.DcPurchases.DcPurchase
  alias Console.Organizations.Organization
  alias Console.Organizations
  alias Console.NetIds

  def get_by_payment_id(id) do
    DcPurchase
      |> where([d], d.payment_id == ^id)
      |> Repo.one()
  end

  def create_dc_purchase_update_org(attrs \\ %{}, %Organization{} = organization) do
    Repo.transaction(fn ->
      new_balance =
        case organization.dc_balance do
          nil -> attrs["dc_purchased"]
          _ -> attrs["dc_purchased"] + organization.dc_balance
        end

      organization = Organizations.get_organization_and_lock_for_dc(organization.id)
      organization
      |> Organization.update_changeset(%{ "dc_balance" => new_balance, "dc_balance_nonce" => organization.dc_balance_nonce + 1, "pending_automatic_purchase" => false })
      |> Repo.update!()


      net_id_values = NetIds.get_all_for_organization(organization.id) |> Enum.map(fn n -> n.value end)
      if new_balance > 0 do
        ConsoleWeb.Endpoint.broadcast("net_id:all", "net_id:all:keep_purchasing", %{ net_ids: [net_id_values]})
      end

      %DcPurchase{}
      |> DcPurchase.changeset(attrs)
      |> Repo.insert!()
    end)
  end

  def create_dc_purchase(attrs \\ %{}) do
    %DcPurchase{}
    |> DcPurchase.changeset(attrs)
    |> Repo.insert()
  end
end
