defmodule ConsoleWeb.NetIdController do
  use ConsoleWeb, :controller
  alias Console.NetIds

  plug ConsoleWeb.Plug.AuthorizeAction

  action_fallback(ConsoleWeb.FallbackController)

  def create(conn, %{"net_ids" => net_ids}) do
    current_organization = conn.assigns.current_organization
    # with {:ok, %ApiKey{} = api_key} <- ApiKeys.create_api_key(current_organization, current_user, params) do
    #   ConsoleWeb.Endpoint.broadcast("graphql:api_keys", "graphql:api_keys:#{conn.assigns.current_organization.id}:api_key_list_update", %{})
    #   Email.api_key_email(current_user, api_key) |> Mailer.deliver_later()
    #
    #   conn
    #   |> put_status(:created)
    #   |> put_resp_header("message",  "API Key #{api_key.name} added successfully")
    #   |> render("show.json", api_key: api_key, key: key)
    # end
  end
end
