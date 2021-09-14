defmodule Console.Factory do
  import Plug.Conn
  use ExMachina.Ecto, repo: Console.Repo

  alias Console.Organizations
  alias Console.Organizations.Organization
  alias Console.ApiKeys.ApiKey
  alias Console.Labels.Label
  alias Console.Labels.DevicesLabels
  alias Console.Channels.Channel
  alias Console.Devices.Device
  alias Console.Functions.Function
  alias Console.Organizations.Membership
  alias Console.Alerts.Alert
  alias Console.Alerts.AlertNode
  alias Console.Flows.Flow

  def authenticate_user(%{conn: conn}) do
    user = params_for(:user)
    {:ok, organization} = Organizations.create_organization(user, params_for(:organization))
    conn = conn
           |> put_req_header("accept", "application/json")
           |> put_req_header("authorization", user.id <> " " <> user.email)
           |> put_req_header("organization", organization.id)
    {:ok, conn: conn}
  end

  def user_factory do
    %{
      id: sequence(:id, &"abcdefghijklmnopqrstuvwxyz#{&1}"),
      email: sequence(:email, &"email-#{&1}@example.com"),
    }
  end

  def organization_factory do
    %Organization{
      name: sequence(:name, &"Organization #{&1}"),
    }
  end

  def api_key_factory do
    %ApiKey{
      name: sequence(:name, &"Api Key #{&1}"),
      role: "admin",
      key: "key",
      user_id: "me"
    }
  end

  def alert_factory do
    %Alert{}
  end

  def alert_node_factory do
    %AlertNode{}
  end
end
