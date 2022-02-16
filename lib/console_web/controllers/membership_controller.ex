defmodule ConsoleWeb.MembershipController do
  use ConsoleWeb, :controller

  alias Console.Organizations
  alias Console.Alerts
  alias Console.Email
  alias Console.Mailer

  plug ConsoleWeb.Plug.AuthorizeAction

  action_fallback(ConsoleWeb.FallbackController)

  def update(conn, %{"id" => id, "membership" => attrs}) do
    current_organization = conn.assigns.current_organization
    current_user = conn.assigns.current_user
    membership = Organizations.get_membership!(current_organization, id)

    if current_user.id == membership.user_id do
      {:error, :forbidden, "Cannot update your own membership"}
    else
      with {:ok, _} <- Organizations.update_membership(membership, attrs) do
        ConsoleWeb.Endpoint.broadcast("graphql:members_table", "graphql:members_table:#{conn.assigns.current_organization.id}:member_list_update", %{})
        
        # send alert email (if applicable)
        current_organization = Organizations.get_organization!(current_organization.id)
        alert = Alerts.get_alert(current_organization)
        if alert != nil and alert.config["users_updated"]["email"]["active"] do
          recipient_emails = Alerts.get_alert_recipient_emails(current_organization, alert.config["users_updated"]["email"]["recipient"])
          Email.user_updated_email(membership.email, current_user, current_organization, recipient_emails) |> Mailer.deliver_later()
        end

        conn
        |> put_resp_header("message", "User role updated successfully")
        |> render("show.json", membership: membership)
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    current_organization = conn.assigns.current_organization
    current_user = conn.assigns.current_user
    membership = Organizations.get_membership!(current_organization, id)

    if current_user.id == membership.user_id do
      {:error, :forbidden, "Cannot delete your own membership"}
    else
      with {:ok, _} <- Organizations.delete_membership(membership) do
        ConsoleWeb.Endpoint.broadcast("graphql:members_table", "graphql:members_table:#{conn.assigns.current_organization.id}:member_list_update", %{})

        # send alert email (if applicable)
        current_organization = Organizations.get_organization!(current_organization.id)
        alert = Alerts.get_alert(current_organization)
        if alert != nil and alert.config["users_updated"]["email"]["active"] do
          recipient_emails = Alerts.get_alert_recipient_emails(current_organization, alert.config["users_updated"]["email"]["recipient"])
          Email.user_deleted_email(membership.email, current_user, current_organization, recipient_emails) |> Mailer.deliver_later()
        end

        conn
        |> put_resp_header("message", "User removed from organization")
        |> send_resp(:no_content, "")
      end
    end
  end
end
