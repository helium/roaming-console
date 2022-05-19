defmodule ConsoleWeb.NetIdController do
  use ConsoleWeb, :controller
  alias Console.NetIds
  alias Console.AuditActions
  alias Console.Organizations

  plug ConsoleWeb.Plug.AuthorizeAction

  action_fallback(ConsoleWeb.FallbackController)

  def update(conn, attrs = %{"id" => id, "protocol" => protocol}) do
    net_id = NetIds.get_net_id!(conn.assigns.current_user, id)
    organization = Organizations.get_organization!(conn.assigns.current_user, net_id.organization_id)
    membership = Organizations.get_membership!(conn.assigns.current_user, organization)

    if membership.role != "admin" do
      {:error, :forbidden, "You don't have access to do this"}
    else
      update_attrs = 
        case protocol do
          "udp" ->
            Map.take(attrs, ["protocol", "address", "port", "disable_pull_data", "join_credentials", "multi_buy"])
          "http" ->
            Map.take(attrs, ["protocol", "http_endpoint", "http_flow_type", "http_dedupe_timeout", "join_credentials", "multi_buy"])
        end

      with {:ok, _} <- NetIds.update_net_id(net_id, %{"config" => update_attrs}) do
        ConsoleWeb.Endpoint.broadcast("graphql:configuration_index", "graphql:configuration_index:#{net_id.organization_id}:settings_update", %{})
        broadcast_packet_purchaser_all_org_config()

        current_organization = conn.assigns.current_organization
        current_email = conn.assigns.current_user.email
        AuditActions.create_audit_action(
          current_organization.id,
          current_email,
          "net_id_controller_update",
          attrs
        )

        conn
        |> put_resp_header("message", "Settings for Net ID #{Integer.to_string(net_id.value, 16)} updated successfully")
        |> send_resp(:no_content, "")
      end
    end
  end

  def update(conn, %{"id" => id, "active" => active}) do
    net_id = NetIds.get_net_id!(conn.assigns.current_user, id)
    organization = Organizations.get_organization!(conn.assigns.current_user, net_id.organization_id)
    membership = Organizations.get_membership!(conn.assigns.current_user, organization)

    if membership.role != "admin" do
      {:error, :forbidden, "You don't have access to do this"}
    else
      with {:ok, _} <- NetIds.update_net_id(net_id, %{"active" => active}) do
        ConsoleWeb.Endpoint.broadcast("graphql:configuration_index", "graphql:configuration_index:#{net_id.organization_id}:settings_update", %{})
        broadcast_packet_purchaser_all_org_config()

        current_organization = conn.assigns.current_organization
        current_email = conn.assigns.current_user.email
        AuditActions.create_audit_action(
          current_organization.id,
          current_email,
          "net_id_controller_update",
          %{ "active" => active }
        )

        conn
        |> put_resp_header("message", "Net ID #{Integer.to_string(net_id.value, 16)} updated successfully")
        |> send_resp(:no_content, "")
      end
    end
  end

  def broadcast_packet_purchaser_all_org_config() do
    results = Organizations.get_all_org_config
    ConsoleWeb.Endpoint.broadcast("organization:all", "organization:all:config:list", %{ org_config_list: results })
  end
end
