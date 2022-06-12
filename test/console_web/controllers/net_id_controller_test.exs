defmodule ConsoleWeb.NetIdControllerTest do
  use ConsoleWeb.ConnCase

  import Console.Factory

  alias Console.NetIds

  describe "organizations" do
    setup [:authenticate_user]

    test "update net id config properly", %{conn: conn} do
      current_organization_id = conn |> get_req_header("organization") |> List.first()

      # net id creation is still manual
      net_id = insert(:net_id, %{ organization_id: current_organization_id, value: 123 })

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "some_id", "protocol" => "udp" }
      assert response(resp_conn, 422) # missing address, should not update

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "some_id", "protocol" => "udp", "address" => "123" }
      assert response(resp_conn, 422) # invalid address, should not update

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "some_id", "protocol" => "udp", "address" => "hello.com" }
      assert response(resp_conn, 422) # missing port, should not update

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "some_id", "protocol" => "udp", "address" => "hello.com", "port" => 65536 }
      assert response(resp_conn, 422) # invalid port, should not update 

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "some_id", "protocol" => "udp", "address" => "hello.com", "port" => 65535 }
      assert response(resp_conn, 204) # valid udp config, should update

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "some_id", "protocol" => "udp", "address" => "hello.com", "port" => 65535, "multi_buy" => -2 }
      assert response(resp_conn, 422) # invalid multi_buy, should not update

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "some_id", "protocol" => "http" }
      assert response(resp_conn, 422) # missing endpoint, should not update

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "some_id", "protocol" => "http", "http_endpoint" => "123" }
      assert response(resp_conn, 422) # invalid endpoint, should not update

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "id_1", "protocol" => "http", "http_endpoint" => "hello.com" }
      assert response(resp_conn, 422) # missing http_flow_type, should not update

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "id_1", "protocol" => "http", "http_endpoint" => "hello.com", "http_flow_type" => "random" }
      assert response(resp_conn, 422) # invalid http_flow_type, should not update

      resp_conn = put conn, net_id_path(conn, :update, net_id.id), %{ "config_id" => "id_1", "protocol" => "http", "http_endpoint" => "hello.com", "http_flow_type" => "async" }
      assert response(resp_conn, 204) # valid http config, should update

      net_id = NetIds.get_net_id(123)
      assert length(net_id.config) == 2 # can add multiple configs
    end

    test "remove net id config properly", %{conn: conn} do
      current_organization_id = conn |> get_req_header("organization") |> List.first()

      # net id creation is still manual
      net_id = insert(:net_id, %{ organization_id: current_organization_id, value: 456, config: [%{ "config_id" => "some_id", "protocol" => "udp", "address" => "hello.com", "port" => 655 }, %{ "config_id" => "some_other_id", "protocol" => "udp", "address" => "goodbye.com", "port" => 399 }] })

      resp_conn = delete conn, net_id_path(conn, :remove_config, net_id.id, "some_id")
      assert response(resp_conn, 204)
      net_id = NetIds.get_net_id(456)
      assert length(net_id.config) == 1 # one config should remain after deletion of another
    end
  end
end