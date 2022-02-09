defmodule ConsoleWeb.OrganizationController do
  use ConsoleWeb, :controller

  alias Console.Organizations.Organization
  alias Console.Organizations
  alias Console.DcPurchases
  alias Console.Email
  alias Console.Mailer

  plug ConsoleWeb.Plug.AuthorizeAction when action in [:delete]

  action_fallback ConsoleWeb.FallbackController

  def index(conn, _) do
    organizations =
      if conn.assigns.current_user.super do
        Organizations.list_organizations()
      else
        last_viewed_membership = Organizations.get_last_viewed_org_membership(conn.assigns.current_user) |> List.first()
        if last_viewed_membership != nil do
          user_orgs = Organizations.get_organizations(conn.assigns.current_user)
          Enum.filter(user_orgs, fn x -> x.id == last_viewed_membership.organization_id end) ++ Enum.filter(user_orgs, fn x -> x.id != last_viewed_membership.organization_id end)
        else
          Organizations.get_organizations(conn.assigns.current_user)
        end
      end

    conn
    |> put_status(:ok)
    |> render("index.json", organizations: organizations)
  end

  def create(conn, %{"organization" => %{ "name" => organization_name } }) do
    with {:ok, %Organization{} = organization} <-
      Organizations.create_organization(conn.assigns.current_user, %{ "name" => organization_name }) do
      organizations = Organizations.get_organizations(conn.assigns.current_user)
      membership = Organizations.get_membership!(conn.assigns.current_user, organization)
      membership_info = %{id: organization.id, name: organization.name, role: membership.role}
      case Enum.count(organizations) do
        1 ->
          Organizations.update_organization(organization, %{ "dc_balance" => System.get_env("INITIAL_ORG_GIFTED_DC") || 10000, "dc_balance_nonce" => 1, "received_free_dc" => true })

          render(conn, "show.json", organization: membership_info)
        _ ->
          ConsoleWeb.Endpoint.broadcast("graphql:orgs_index_table", "graphql:orgs_index_table:#{conn.assigns.current_user.id}:organization_list_update", %{})

          conn
          |> put_status(:created)
          |> put_resp_header("message",  "Organization #{organization.name} added successfully")
          |> render("show.json", organization: membership_info)
      end
    end
  end

  def update(conn, %{"id" => id, "active" => active}) do
    organization = Organizations.get_organization!(conn.assigns.current_user, id)
    membership = Organizations.get_membership!(conn.assigns.current_user, organization)

    if membership.role != "admin" do
      {:error, :forbidden, "You don't have access to do this"}
    else
      Organizations.update_organization(organization, %{ "active" => active })
      ConsoleWeb.Endpoint.broadcast("graphql:orgs_index_table", "graphql:orgs_index_table:#{conn.assigns.current_user.id}:organization_list_update", %{})
      broadcast_packet_purchaser_all_org_config()

      render_org = %{id: organization.id, name: organization.name, role: membership.role}
      conn
      |> put_resp_header("message", "Organization #{organization.name} updated successfully")
      |> render("show.json", organization: render_org)
    end
  end

  def update(conn, attrs = %{"id" => id, "address" => _, "port" => _, "join_credentials" => _, "multi_buy" => _}) do
    organization = Organizations.get_organization!(conn.assigns.current_user, id)
    membership = Organizations.get_membership!(conn.assigns.current_user, organization)

    if membership.role != "admin" do
      {:error, :forbidden, "You don't have access to do this"}
    else
      update_attrs = Map.take(attrs, ["address", "port", "join_credentials", "multi_buy"])
      with {:ok, _} <- Organizations.update_organization(organization, update_attrs) do
        ConsoleWeb.Endpoint.broadcast("graphql:configuration_index", "graphql:configuration_index:#{id}:settings_update", %{})
        broadcast_packet_purchaser_all_org_config()

        conn
        |> put_resp_header("message", "Settings for organization #{organization.name} updated successfully")
        |> send_resp(:no_content, "")
      end
    end
  end

  def update(conn, %{"switch_org_id" => org_id}) do
    organization = Organizations.get_organization!(conn.assigns.current_user, org_id)
    membership = Organizations.get_membership!(conn.assigns.current_user, organization)

    with {:ok, _} <- Organizations.update_membership(membership, %{ updated_at: NaiveDateTime.utc_now() }) do
      conn
      |> send_resp(:no_content, "")
    end
  end

  def delete(conn, %{"id" => id, "destination_org_id" => destination_org_id}) do
    organization = Organizations.get_organization!(conn.assigns.current_user, id)
    membership = Organizations.get_membership!(conn.assigns.current_user, organization)
    balance_left = organization.dc_balance

    cond do
      membership.role != "admin" ->
        {:error, :forbidden, "You don't have access to do this"}
      organization.received_free_dc and balance_left < 10001 and destination_org_id != "no-transfer" ->
        {:error, :forbidden, "You cannot transfer the original gifted 10,000 DC to other organizations"}
      true ->
        destination_org =
          case destination_org_id do
            "no-transfer" -> nil
            _ -> Organizations.get_organization(conn.assigns.current_user, destination_org_id)
          end

        if balance_left != nil and balance_left > 0 and destination_org != nil do
          balance_to_transfer =
            if organization.received_free_dc do
              balance_left - 10000
            else
              balance_left
            end

          {:ok, {:ok, from_org_updated, to_org_updated }} = Organizations.send_dc_to_org(balance_to_transfer, organization, destination_org)
          ConsoleWeb.Endpoint.broadcast("graphql:dc_index", "graphql:dc_index:#{from_org_updated.id}:update_dc", %{})
          ConsoleWeb.Endpoint.broadcast("graphql:dc_index", "graphql:dc_index:#{to_org_updated.id}:update_dc", %{})
          ConsoleWeb.DataCreditController.broadcast_packet_purchaser_refill_dc_balance(from_org_updated)
          ConsoleWeb.DataCreditController.broadcast_packet_purchaser_refill_dc_balance(to_org_updated)

          attrs = %{
            "dc_purchased" => balance_to_transfer,
            "cost" => 0,
            "card_type" => "transfer",
            "last_4" => "transfer",
            "user_id" => conn.assigns.current_user.id,
            "from_organization" => organization.name,
            "organization_id" => destination_org.id
          }

          {:ok, _destination_org_dc_purchase} = DcPurchases.create_dc_purchase(attrs)
          ConsoleWeb.Endpoint.broadcast("graphql:dc_purchases_table", "graphql:dc_purchases_table:#{destination_org.id}:update_dc_table", %{})
        end

        admins = Organizations.get_administrators(organization)

        with {:ok, _} <- Organizations.delete_organization(organization) do
          Enum.each(admins, fn administrator ->
            Email.delete_org_alert_email(organization, administrator.email, membership.email)
            |> Mailer.deliver_later()
          end)

          ConsoleWeb.Endpoint.broadcast("graphql:orgs_index_table", "graphql:orgs_index_table:#{conn.assigns.current_user.id}:organization_list_update", %{})
          broadcast_packet_purchaser_all_org_config()

          render_org = %{id: organization.id, name: organization.name, role: membership.role}
          conn
          |> put_status(:accepted)
          |> put_resp_header("message",  "#{organization.name} deleted successfully")
          |> render("show.json", organization: render_org)
        end
    end
  end

  def get_net_ids(conn, _) do
    case conn.assigns.current_user.email do
      "jeffrey@helium.com" ->
        results = Organizations.get_all_org_config() |> Poison.encode!()

        conn
        |> send_resp(:ok, results)
      _ ->
        {:error, :forbidden, "You don't have access to do this"}
    end
  end

  def broadcast_packet_purchaser_all_org_balance() do
    results = Organizations.get_all_org_dc_balance
    ConsoleWeb.Endpoint.broadcast("organization:all", "organization:all:dc_balance:list", %{ org_dc_balance_list: results })
  end

  def broadcast_packet_purchaser_all_org_config() do
    results = Organizations.get_all_org_config
    ConsoleWeb.Endpoint.broadcast("organization:all", "organization:all:config:list", %{ org_config_list: results })
  end
end
