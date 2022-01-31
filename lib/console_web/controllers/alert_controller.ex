defmodule ConsoleWeb.AlertController do
  use ConsoleWeb, :controller
  alias Console.Alerts

  plug ConsoleWeb.Plug.AuthorizeAction

  action_fallback(ConsoleWeb.FallbackController)

  def create(conn, %{ "settings" => settings }) do
    current_organization = conn.assigns.current_organization

    case Alerts.get_alert(current_organization) do
      nil ->
        with {:ok, _} <- Alerts.create_alert(%{ "config" => settings }, current_organization) do
          ConsoleWeb.Endpoint.broadcast("graphql:alerts_index", "graphql:alerts_index:#{current_organization.id}:alerts_update", %{})

          conn
          |> put_resp_header("message", "Alerts updated for current organization")
          |> send_resp(:no_content, "")
        end
      alert ->
        with {:ok, _} <- Alerts.update_alert(%{ "config" => settings }, alert) do
          ConsoleWeb.Endpoint.broadcast("graphql:alerts_index", "graphql:alerts_index:#{current_organization.id}:alerts_update", %{})
          
          conn
          |> put_resp_header("message", "Alerts updated for current organization")
          |> send_resp(:no_content, "")
        end
    end
  end
end
