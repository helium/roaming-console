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

    config_attrs = 
      case protocol do
        "udp" ->
          Map.take(attrs, ["config_id", "protocol", "address", "port", "disable_pull_data", "join_credentials", "multi_buy", "devaddrs"])
        "http" ->
          Map.take(attrs, ["config_id", "protocol", "http_endpoint", "http_flow_type", "http_dedupe_timeout", "join_credentials", "multi_buy", "devaddrs"])
      end

    config_attrs = case Map.get(config_attrs, "config_id") do
      nil -> Map.put(config_attrs, "config_id", Ecto.UUID.generate())
      _ -> config_attrs
    end
    
    new_config = case net_id.config do
      [] ->
        [config_attrs]
      _ ->
        [config_attrs | Enum.filter(net_id.config, fn c -> c["config_id"] != config_attrs["config_id"] end)]
    end

    # TODO map http_headers

    with {:ok, _} <- NetIds.update_net_id(net_id, %{"config" => new_config, "http_headers" => attrs["http_headers"]}) do
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
      |> put_resp_header("message", "Settings for Net ID #{Integer.to_string(net_id.value, 16)} config updated successfully")
      |> send_resp(:no_content, "")
    end
  end

  def update(conn, %{"id" => id, "config_id" => config_id, "active" => active}) do
    net_id = NetIds.get_net_id!(conn.assigns.current_user, id)
    organization = Organizations.get_organization!(conn.assigns.current_user, net_id.organization_id)

    updated_config = Enum.find(net_id.config, fn c -> c["config_id"] == config_id end) |> Map.put("active", active)
    config = [ updated_config | Enum.filter(net_id.config, fn c -> c["config_id"] != config_id end)]

    with {:ok, _} <- NetIds.update_net_id(net_id, %{"config" => config}) do
      ConsoleWeb.Endpoint.broadcast("graphql:configuration_index", "graphql:configuration_index:#{net_id.organization_id}:settings_update", %{})
      broadcast_packet_purchaser_all_org_config()

      current_organization = conn.assigns.current_organization
      current_email = conn.assigns.current_user.email
      AuditActions.create_audit_action(
        current_organization.id,
        current_email,
        "net_id_controller_update",
        %{ "config_id" => config_id, "id" => id, "active" => active }
      )

      conn
      |> put_resp_header("message", "Net ID #{Integer.to_string(net_id.value, 16)} config updated successfully")
      |> send_resp(:no_content, "")
    end
  end

  def remove_config(conn, %{"id" => id, "config_id" => config_id}) do
    net_id = NetIds.get_net_id!(conn.assigns.current_user, id)
    organization = Organizations.get_organization!(conn.assigns.current_user, net_id.organization_id)

    config = Enum.filter(net_id.config, fn c -> c["config_id"] != config_id end)
    with {:ok, _} <- NetIds.update_net_id(net_id, %{"config" => config}) do
      ConsoleWeb.Endpoint.broadcast("graphql:configuration_index", "graphql:configuration_index:#{net_id.organization_id}:settings_update", %{})
      broadcast_packet_purchaser_all_org_config()

      current_organization = conn.assigns.current_organization
      current_email = conn.assigns.current_user.email
      AuditActions.create_audit_action(
        current_organization.id,
        current_email,
        "net_id_controller_remove_config",
        %{ "config_id" => config_id, "id" => id }
      )

      conn
      |> put_resp_header("message", "Config removed from Net ID #{Integer.to_string(net_id.value, 16)} successfully")
      |> send_resp(:no_content, "")
    end
  end

  def broadcast_packet_purchaser_all_org_config() do
    results = Organizations.get_all_org_config
    ConsoleWeb.Endpoint.broadcast("organization:all", "organization:all:config:list", %{ org_config_list: results })
  end
end
