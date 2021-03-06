defmodule Console.Email do
  use Bamboo.Phoenix, view: ConsoleWeb.EmailView

  alias Console.Auth.User
  alias Console.ApiKeys.ApiKey
  alias Console.DcPurchases.DcPurchase
  alias Console.Organizations.Invitation
  alias Console.Organizations.Organization
  alias DateTime

  def dc_transfer_source_alert(from_org, to_org, dc_transferred, user, recipient) do
    dc_transfer_alert_email(from_org.name, from_org.name, to_org.name, dc_transferred, from_org.dc_balance, user, recipient)
  end

  def dc_transfer_dest_alert(from_org, to_org, dc_transferred, user, recipient) do
    dc_transfer_alert_email(to_org.name, from_org.name, to_org.name, dc_transferred, to_org.dc_balance, user, recipient)
  end

  def dc_top_up_alert_email(%Organization{name: organization_name}, %DcPurchase{dc_purchased: dc_purchased, cost: cost}, recipient) do
    formatted_credits = dc_format(dc_purchased)
    base_email()
    |> to(recipient)
    |> subject("Data credit automatic renewal")
    |> assign(:dc_purchased, formatted_credits)
    |> assign(:date_time, current_time())
    |> assign(:organization_name, organization_name)
    |> assign(:cost, cost/100 |> Decimal.from_float() |> Decimal.round(2))
    |> render(:data_credit_top_up)
  end

  def delete_org_alert_email(%Organization{name: organization_name}, recipient, deleted_by) do
    base_email()
    |> to(recipient)
    |> subject("An organization was deleted from Helium Roaming Console")
    |> assign(:organization_name, organization_name)
    |> assign(:deleted_by_name, deleted_by)
    |> assign(:date_time, current_time())
    |> render(:delete_organization_notice)
  end

  def dc_balance_alert_email(%Organization{name: organization_name}, dc_balance, recipient) do
    base_email()
    |> to(recipient)
    |> subject("Data credit low balance alert")
    |> assign(:balance, dc_balance)
    |> assign(:organization_name, organization_name)
    |> assign(:date_time, current_time())
    |> render(:data_credit_balance_notice)
  end

  def payment_method_updated_email(%User{email: updater_email}, %Organization{name: organization_name}, recipient, action) do
    base_email()
    |> to(recipient)
    |> subject("Payment method change alert")
    |> assign(:updater_email, updater_email)
    |> assign(:organization_name, organization_name)
    |> assign(:date_time, current_time())
    |> assign(:action, action)
    |> render(:payment_method_change)
  end

  def data_credit_purchase_email(%DcPurchase{dc_purchased: dc_purchased, cost: cost}, %User{email: purchaser_email}, %Organization{name: organization_name}, recipient) do
    formatted_credits = dc_format(dc_purchased)

    base_email()
    |> to(recipient)
    |> subject("Data credit purchase alert")
    |> assign(:purchaser_email, purchaser_email)
    |> assign(:organization_name, organization_name)
    |> assign(:dc_purchased, formatted_credits)
    |> assign(:date_time, current_time())
    |> assign(:cost, cost/100 |> Decimal.from_float() |> Decimal.round(2))
    |> render(:data_credit_purchase)
  end

  def invitation_email(%Invitation{email: email, token: token, role: role}, %User{email: inviter_email}, %Organization{name: organization_name}) do
    role_hash = %{ "admin" => "Administrator", "read" => "Read-Only", "manager" => "Manager" }

    base_email()
    |> to(email)
    |> subject("You've been invited to join Helium")
    |> assign(:token, token)
    |> assign(:inviter_email, inviter_email)
    |> assign(:role, Map.fetch!(role_hash, role))
    |> assign(:organization_name, organization_name)
    |> render(:invitation_email)
  end

  def resend_invitation_email(%Invitation{email: email, token: token, role: role}, inviter_email, %Organization{name: organization_name}) do
    role_hash = %{ "admin" => "Administrator", "read" => "Read-Only", "manager" => "Manager" }

    base_email()
    |> to(email)
    |> subject("You've been invited to join Helium")
    |> assign(:token, token)
    |> assign(:inviter_email, inviter_email)
    |> assign(:role, Map.fetch!(role_hash, role))
    |> assign(:organization_name, organization_name)
    |> render(:invitation_email)
  end

  def api_key_email(%User{email: email}, %ApiKey{token: token, name: name}) do
    base_email()
    |> to(email)
    |> subject("Activate your new Helium API Key")
    |> assign(:token, token)
    |> assign(:key_name, name)
    |> render(:api_key_email)
  end

  defp base_email do
    # This will use the "email.html.eex" file as a layout when rendering html emails.
    # Plain text emails will not use a layout unless you use `put_text_layout`
    new_email()
    |> from(System.get_env("MAIL_FROM") || "Helium <roaming-console@helium.com>")
    |> put_header("Reply-To", System.get_env("MAIL_REPLY_TO") || "roaming-console@helium.com")
    |> put_html_layout({ConsoleWeb.LayoutView, "email.html"})
    |> assign(:url, System.get_env("SOCKET_CHECK_ORIGIN") || "http://localhost:4000")
  end

  defp current_time do
    dt = DateTime.utc_now()
    minute = if (dt.minute < 10), do: "0#{dt.minute}", else: dt.minute
    "#{dt.hour}:#{minute} #{dt.zone_abbr} on #{dt.month}/#{dt.day}/#{dt.year}"
  end

  defp dc_format(dc) do
    dc
    |> Integer.to_charlist
    |> Enum.reverse
    |> Enum.chunk_every(3, 3, [])
    |> Enum.join(",")
    |> String.reverse
  end

  defp dc_transfer_alert_email(organization_name, source_organization_name, destination_organization_name, dc_transfered, balance, %User{email: transferer_email}, recipient) do
    formatted_credits = dc_format(dc_transfered)
    base_email()
    |> to(recipient)
    |> subject("Data credit transfer alert")
    |> assign(:organization_name, organization_name)
    |> assign(:source_organization, source_organization_name)
    |> assign(:destination_organization, destination_organization_name)
    |> assign(:transferer_email, transferer_email)
    |> assign(:transfer_amount, formatted_credits)
    |> assign(:balance, dc_format(balance))
    |> assign(:date_time, current_time())
    |> render(:data_credit_transfer)
  end

  def payments_update_email(%User{email: email}, %Organization{name: organization_name}, recipients) do
    base_email()
    |> to(recipients)
    |> subject("Payment Method Alert")
    |> assign(:user_email, email)
    |> assign(:organization_name, organization_name)
    |> assign(:date_time, current_time())
    |> render(:payments_update)
  end

  def payments_removed_email(%User{email: email}, %Organization{name: organization_name}, recipients) do
    base_email()
    |> to(recipients)
    |> subject("Payment Method Alert")
    |> assign(:user_email, email)
    |> assign(:organization_name, organization_name)
    |> assign(:date_time, current_time())
    |> render(:payments_update)
  end

  def user_invited_email(invitee_email, %User{email: email}, %Organization{name: organization_name}, recipients) do
    base_email()
    |> to(recipients)
    |> subject("User Alert")
    |> assign(:invitee_email, invitee_email)
    |> assign(:user_email, email)
    |> assign(:organization_name, organization_name)
    |> assign(:date_time, current_time())
    |> render(:user_invited)
  end

  def user_deleted_email(deleted_user_email, %User{email: email}, %Organization{name: organization_name}, recipients) do
    base_email()
    |> to(recipients)
    |> subject("User Alert")
    |> assign(:deleted_user_email, deleted_user_email)
    |> assign(:user_email, email)
    |> assign(:organization_name, organization_name)
    |> assign(:date_time, current_time())
    |> render(:user_deleted)
  end

  def user_updated_email(updated_user_email, %User{email: email}, %Organization{name: organization_name}, recipients) do
    base_email()
    |> to(recipients)
    |> subject("User Alert")
    |> assign(:updated_user_email, updated_user_email)
    |> assign(:user_email, email)
    |> assign(:organization_name, organization_name)
    |> assign(:date_time, current_time())
    |> render(:user_updated)
  end
end
