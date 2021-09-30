defmodule ConsoleWeb.NotificationController do
  use ConsoleWeb, :controller
  alias Console.Notifications

  plug ConsoleWeb.Plug.AuthorizeAction

  action_fallback(ConsoleWeb.FallbackController)

  def create(conn, %{ "settings" => settings }) do
    current_organization = conn.assigns.current_organization

    case Notifications.get_notification(current_organization) do
      nil ->
        with {:ok, _} <- Notifications.create_notification(%{ "config" => settings }, current_organization) do
          ConsoleWeb.Endpoint.broadcast("graphql:notifications_index", "graphql:notifications_index:#{current_organization.id}:notifications_update", %{})

          conn
          |> put_resp_header("message", "Notifications updated for current organization")
          |> send_resp(:no_content, "")
        end
      notification ->
        with {:ok, _} <- Notifications.update_notification(%{ "config" => settings }, notification) do
          ConsoleWeb.Endpoint.broadcast("graphql:notifications_index", "graphql:notifications_index:#{current_organization.id}:notifications_update", %{})
          
          conn
          |> put_resp_header("message", "Notifications updated for current organization")
          |> send_resp(:no_content, "")
        end
    end
  end
end
