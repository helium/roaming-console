defmodule ConsoleWeb.DataCreditController do
  use ConsoleWeb, :controller
  alias Console.Email
  alias Console.Memos
  alias Console.Organizations
  alias Console.NetIds
  alias Console.DcPurchases
  alias Console.DcPurchases.DcPurchase
  alias Console.Organizations.Organization
  alias Console.Mailer
  alias Console.Alerts
  alias Console.Repo

  plug ConsoleWeb.Plug.AuthorizeAction
  action_fallback(ConsoleWeb.FallbackController)

  @stripe_api_url "https://api.stripe.com"
  @headers [
    {"Authorization", "Bearer #{Application.get_env(:console, :stripe_secret_key)}"},
    {"Content-Type", "application/x-www-form-urlencoded"}
  ]

  def create_customer_id_and_charge(conn, %{ "amountUSD" => amountUSD }) do
    { amount, _ } = Float.parse(amountUSD)
    if amount < 10 do
      {:error, :bad_request, "Credit card charges cannot be less than $10"}
    else
      current_organization = conn.assigns.current_organization

      request_body = URI.encode_query(%{
        "name" => current_organization.name,
        "description" => current_organization.id,
      })
      # create a customer id in stripe
      with {:ok, stripe_response} <- HTTPoison.post("#{@stripe_api_url}/v1/customers", request_body, @headers) do
         with 200 <- stripe_response.status_code do
           customer = Poison.decode!(stripe_response.body)
           with {:ok, %Organization{} = organization} <- Organizations.update_organization(current_organization, %{ "stripe_customer_id" => customer["id"]}) do
             # create a payment intent in stripe
             request_body = URI.encode_query(%{
               "customer" => organization.stripe_customer_id,
               "amount" => Float.round(amount * 100) |> trunc(),
               "currency" => "usd",
               "receipt_email" => conn.assigns.current_user.email
             })

             with {:ok, stripe_response} <- HTTPoison.post("#{@stripe_api_url}/v1/payment_intents", request_body, @headers) do
               with 200 <- stripe_response.status_code do
                 payment_intent = Poison.decode!(stripe_response.body)
                 conn |> send_resp(:ok, Poison.encode!(%{ payment_intent_secret: payment_intent["client_secret"] }))
               end
             end
           end
         end
      end
    end
  end

  def create_charge(conn, %{ "amountUSD" => amountUSD }) do
    { amount, _ } = Float.parse(amountUSD)

    if amount < 10 do
      {:error, :bad_request, "Credit card charges cannot be less than $10"}
    else
      current_organization = conn.assigns.current_organization
      request_body = URI.encode_query(%{
        "customer" => current_organization.stripe_customer_id,
        "amount" => Float.round(amount * 100) |> trunc(),
        "currency" => "usd",
        "receipt_email" => conn.assigns.current_user.email
      })

      with {:ok, stripe_response} <- HTTPoison.post("#{@stripe_api_url}/v1/payment_intents", request_body, @headers) do
        with 200 <- stripe_response.status_code do
          payment_intent = Poison.decode!(stripe_response.body)
          conn |> send_resp(:ok, Poison.encode!(%{ payment_intent_secret: payment_intent["client_secret"] }))
        end
      end
    end
  end

  def get_payment_methods(conn, _) do
    current_organization = conn.assigns.current_organization

    with {:ok, stripe_response} <- HTTPoison.get("#{@stripe_api_url}/v1/payment_methods?customer=#{current_organization.stripe_customer_id}&type=card", @headers) do
      with 200 <- stripe_response.status_code do
        conn |> send_resp(:ok, stripe_response.body)
      end
    end
  end

  def get_setup_payment_method(conn, _) do
    current_organization = conn.assigns.current_organization

    request_body = URI.encode_query(%{
      "customer" => current_organization.stripe_customer_id,
    })

    with {:ok, stripe_response} <- HTTPoison.post("#{@stripe_api_url}/v1/setup_intents", request_body, @headers) do
      with 200 <- stripe_response.status_code do
        setup_intent = Poison.decode!(stripe_response.body)
        # Send email about payment method added
        Organizations.get_administrators(current_organization)
        |> Enum.each(fn administrator ->
          conn.assigns.current_user
          |> Email.payment_method_updated_email(current_organization, administrator.email, "added") |> Mailer.deliver_later()
        end)
        conn |> send_resp(:ok, Poison.encode!(%{ setup_intent_secret: setup_intent["client_secret"] }))
      end
    end
  end

  def set_default_payment_method(conn, %{ "defaultPaymentId" => defaultPaymentId }) do
    current_organization = conn.assigns.current_organization

    with {:ok, %Organization{} = _organization} <- Organizations.update_organization(current_organization, %{ "default_payment_id" => defaultPaymentId }) do
      ConsoleWeb.Endpoint.broadcast("graphql:dc_index", "graphql:dc_index:#{current_organization.id}:update_dc", %{})

      # send alert email (if applicable)
      current_organization = Organizations.get_organization!(current_organization.id)
      alert = Alerts.get_alert(current_organization)
      if alert != nil and alert.config["payments_updated"]["email"]["active"] do
        recipient_emails = Alerts.get_alert_recipient_emails(current_organization, alert.config["payments_updated"]["email"]["recipient"])
        Email.payments_update_email(conn.assigns.current_user, current_organization, recipient_emails) |> Mailer.deliver_later()
      end

      conn
      |> put_resp_header("message", "Default payment method updated successfully")
      |> send_resp(:no_content, "")
    end
  end

  def remove_payment_method(conn, %{ "paymentId" => paymentId, "latestAddedCardId" => latestAddedCardId }) do
    current_organization = conn.assigns.current_organization

    request_body = URI.encode_query(%{})

    with {:ok, stripe_response} <- HTTPoison.post("#{@stripe_api_url}/v1/payment_methods/#{paymentId}/detach", request_body, @headers) do
      with 200 <- stripe_response.status_code do
        msg =
          if current_organization.automatic_payment_method == paymentId do
            attrs = %{
              "automatic_charge_amount" => nil,
              "automatic_payment_method" => nil
            }
            Organizations.update_organization(current_organization, attrs)

            "This payment method was used for Automatic Renewal, you will need to set up Automatic Renewals again with a new card."
          else
            "Payment method removed successfully"
          end

        if latestAddedCardId != nil do
          Organizations.update_organization(current_organization, %{ "default_payment_id" => latestAddedCardId })
        end

        # send alert email (if applicable)
        current_organization = Organizations.get_organization!(current_organization.id)
        alert = Alerts.get_alert(current_organization)
        if alert != nil and alert.config["payments_updated"]["email"]["active"] do
          recipient_emails = Alerts.get_alert_recipient_emails(current_organization, alert.config["payments_updated"]["email"]["recipient"])
          Email.payments_removed_email(conn.assigns.current_user, current_organization, recipient_emails) |> Mailer.deliver_later()
        end

        ConsoleWeb.Endpoint.broadcast("graphql:dc_index", "graphql:dc_index:#{current_organization.id}:update_dc", %{})

        conn
        |> put_resp_header("message", msg)
        |> send_resp(:no_content, "")
      end
    end
  end

  def create_dc_purchase(conn, %{"cost" => cost, "cardType" => card_type, "last4" => last_4, "paymentId" => payment_id}) do
    current_organization = conn.assigns.current_organization
    current_user = conn.assigns.current_user
    # Refactor out conversion rates between USD, DC, Bytes later
    attrs = %{
      "dc_purchased" => cost * 1000,
      "cost" => cost,
      "card_type" => card_type,
      "last_4" => last_4,
      "user_id" => current_user.id,
      "organization_id" => current_organization.id,
      "payment_id" => payment_id,
    }

    with nil <- DcPurchases.get_by_payment_id(payment_id),
      {:ok, stripe_response} <- HTTPoison.get("#{@stripe_api_url}/v1/payment_intents/#{payment_id}", @headers),
      200 <- stripe_response.status_code do
        payment_intent = Poison.decode!(stripe_response.body)

        with "succeeded" <- payment_intent["status"],
          {:ok, %DcPurchase{} = dc_purchase } <- DcPurchases.create_dc_purchase_update_org(attrs, current_organization) do
            current_organization = Organizations.get_organization!(current_organization.id)
            Organizations.update_organization(current_organization, %{ "received_free_dc" => false })

            ConsoleWeb.Endpoint.broadcast("graphql:dc_purchases_table", "graphql:dc_purchases_table:#{current_organization.id}:update_dc_table", %{})
            ConsoleWeb.Endpoint.broadcast("graphql:dc_index", "graphql:dc_index:#{current_organization.id}:update_dc", %{})
            broadcast_packet_purchaser_refill_dc_balance(current_organization)

            # send alert email (if applicable)
            alert = Alerts.get_alert(current_organization)
            if alert != nil and alert.config["dc_purchased"]["email"]["active"] do
              recipient_emails = Alerts.get_alert_recipient_emails(current_organization, alert.config["dc_purchased"]["email"]["recipient"])
              Email.data_credit_purchase_email(dc_purchase, current_user, current_organization, recipient_emails) |> Mailer.deliver_later()
            end

            conn
            |> put_resp_header("message", "Payment successful, your Data Credits balance has been refreshed.")
            |> send_resp(:no_content, "")
        end
    end
  end

  def set_automatic_payments(conn, %{ "chargeAmount" => charge_amount, "paymentMethod" => payment_method, "chargeOption" => charge_option }) do
    { amount, _ } = Float.parse(charge_amount)

    if amount < 10 and charge_option != "none" do
      {:error, :bad_request, "Credit card charges cannot be less than $10"}
    else
      current_organization = conn.assigns.current_organization

      attrs =
        case charge_option do
          "none" ->
            %{
              "automatic_charge_amount" => nil,
              "automatic_payment_method" => nil
            }
          _ ->
            %{
              "automatic_charge_amount" => Float.round(amount * 100) |> trunc(),
              "automatic_payment_method" => payment_method
            }
        end

      with {:ok, %Organization{} = _organization} <- Organizations.update_organization(current_organization, attrs) do
        ConsoleWeb.Endpoint.broadcast("graphql:dc_index", "graphql:dc_index:#{current_organization.id}:update_dc", %{})
        conn
        |> put_resp_header("message", "Automatic payments updated successfully")
        |> send_resp(:no_content, "")
      end
    end
  end

  def transfer_dc(conn, %{ "countDC" => countDC, "orgId" => toOrganizationId }) do
    current_organization = conn.assigns.current_organization
    current_user = conn.assigns.current_user

    { amount, _ } = Float.parse(countDC)
    amount = amount |> trunc()

    cond do
      current_organization.received_free_dc && (current_organization.dc_balance - amount) < 10000 ->
        {:error, :bad_request, "You cannot transfer the initial 10000 Data Credits given to you"}
      amount < 1 ->
        {:error, :bad_request, "Please select a higher Data Credit amount for transfer"}
      amount > current_organization.dc_balance ->
        {:error, :bad_request, "You do not have that many Data Credits to transfer"}
      true ->
        to_organization = Organizations.get_organization!(current_user, toOrganizationId)

        with {:ok, {:ok, from_org_updated, to_org_updated }} <- Organizations.send_dc_to_org(amount, current_organization, to_organization) do
          Organizations.get_administrators(from_org_updated)
          |> Enum.each(fn administrator ->
            Email.dc_transfer_source_alert(from_org_updated, to_org_updated, amount, current_user, administrator.email)
            |> Mailer.deliver_later()
          end)
          Organizations.get_administrators(to_org_updated)
          |> Enum.each(fn administrator ->
            Email.dc_transfer_dest_alert(from_org_updated, to_org_updated, amount, current_user, administrator.email)
            |> Mailer.deliver_later()
          end)
          ConsoleWeb.Endpoint.broadcast("graphql:dc_index", "graphql:dc_index:#{from_org_updated.id}:update_dc", %{})
          ConsoleWeb.Endpoint.broadcast("graphql:dc_index", "graphql:dc_index:#{to_org_updated.id}:update_dc", %{})
          broadcast_packet_purchaser_refill_dc_balance(from_org_updated)
          broadcast_packet_purchaser_refill_dc_balance(to_org_updated)

          attrs = %{
            "dc_purchased" => amount,
            "cost" => 0,
            "card_type" => "transfer",
            "last_4" => "transfer",
            "user_id" => current_user.id,
          }

          {:ok, _to_org_dc_purchase} = Map.merge(attrs, %{"from_organization" => from_org_updated.name, "organization_id" => to_org_updated.id })
          |> DcPurchases.create_dc_purchase()
          {:ok, _from_org_dc_purchase} = Map.merge(attrs, %{"to_organization" => to_org_updated.name, "organization_id" => from_org_updated.id })
          |> DcPurchases.create_dc_purchase()
          ConsoleWeb.Endpoint.broadcast("graphql:dc_purchases_table", "graphql:dc_purchases_table:#{from_org_updated.id}:update_dc_table", %{})
          ConsoleWeb.Endpoint.broadcast("graphql:dc_purchases_table", "graphql:dc_purchases_table:#{to_org_updated.id}:update_dc_table", %{})

          conn
          |> put_resp_header("message", "Transfer successful, please verify your new balance in both organizations")
          |> send_resp(:no_content, "")
        end
    end
  end

  def generate_memo(conn, _) do
    current_organization = conn.assigns.current_organization

    number = :rand.uniform(round(:math.pow(2,64))) - 1
    number_bin = :binary.encode_unsigned(number, :little)
    memo_params = %{ "memo" => :base64.encode(number_bin), "organization_id" => current_organization.id }

    with { :ok, memo } <- Memos.create_memo(memo_params) do
      Memos.delete_old_memos(current_organization)

      conn |> send_resp(:ok, Poison.encode!(%{ memo: memo.memo }))
    end
  end

  def get_packet_purchaser_address(conn, _) do
    address = ConsoleWeb.Monitor.get_packet_purchaser_address()
    if address == "" do
      ConsoleWeb.Endpoint.broadcast("organization:all", "organization:all:refetch:packet_purchaser_address", %{})
    end
    conn |> send_resp(:ok, Poison.encode!(%{ address: address }))
  end

  def get_hnt_price(conn, _) do
    with {:ok, current_price_resp} <- HTTPoison.get("https://api.helium.io/v1/oracle/prices/current"),
      200 <- current_price_resp.status_code,
      {:ok, predictions_resp} <- HTTPoison.get("https://api.helium.io/v1/oracle/predictions"),
      200 <- predictions_resp.status_code do
        current_price = Poison.decode!(current_price_resp.body)
        predictions = Poison.decode!(predictions_resp.body)

        next_price_timestamp =
          case predictions["data"] do
            [] ->
              now = DateTime.utc_now() |> DateTime.truncate(:second)
              seconds_to_add = 60 - now.second + (59 - now.minute) * 60
              now |> DateTime.add(seconds_to_add, :second) |> DateTime.to_unix
            list ->
              List.first(list)["time"]
          end

        conn |> send_resp(:ok, Poison.encode!(%{ price: current_price["data"]["price"], next_price_timestamp: next_price_timestamp }))
    else {:error, _} ->
      conn
      |> send_resp(502, "")
    end
  end

  def check_org_dc_balance(organization, prev_dc_balance) do
    # send alert email (if applicable)
    alert = Alerts.get_alert(organization)
    if organization.automatic_charge_amount == nil and alert != nil and alert.config["dc_low"]["email"]["active"] do
      recipient_emails = Alerts.get_alert_recipient_emails(organization, alert.config["dc_low"]["email"]["recipient"])
      cond do
        prev_dc_balance > 500_000 and organization.dc_balance <= 500_000 and organization.dc_balance > 499990 ->
          # # DC Balance has dipped below 500,000. Send an alert.
          Email.dc_balance_alert_email(organization, organization.dc_balance, recipient_emails) |> Mailer.deliver_later()

        prev_dc_balance > 0 and organization.dc_balance <= 0 ->
          # DC Balance has gone to zero. Send a notice.
          Email.dc_balance_alert_email(organization, 0, recipient_emails) |> Mailer.deliver_later()
        true -> nil
      end
    end

    if organization.automatic_charge_amount != nil
      and organization.automatic_payment_method != nil
      and organization.dc_balance < 500000
      and not organization.pending_automatic_purchase do

        {:ok, updated_org_pending_result} =
          Repo.transaction(fn ->
            organization = Organizations.get_organization!(organization.id)
            if organization.pending_automatic_purchase do
              nil
            else
              Organizations.update_organization!(organization, %{ "pending_automatic_purchase" => true })
            end
          end)

        case updated_org_pending_result do
          nil -> nil
          organization ->
            request_body = URI.encode_query(%{
              "customer" => organization.stripe_customer_id,
              "amount" => organization.automatic_charge_amount,
              "currency" => "usd",
              "payment_method" => organization.automatic_payment_method,
              "off_session" => "true",
              "confirm" => "true",
            })

            with {:ok, stripe_response} <- HTTPoison.post("#{@stripe_api_url}/v1/payment_intents", request_body, @headers) do
              with 200 <- stripe_response.status_code do
                payment_intent = Poison.decode!(stripe_response.body)

                with "succeeded" <- payment_intent["status"],
                  {:ok, stripe_response} <- HTTPoison.get("#{@stripe_api_url}/v1/payment_methods/#{payment_intent["payment_method"]}", @headers),
                  200 <- stripe_response.status_code do
                    card = Poison.decode!(stripe_response.body)

                    attrs = %{
                      "dc_purchased" => payment_intent["amount"] * 1000,
                      "cost" => payment_intent["amount"],
                      "card_type" => card["card"]["brand"],
                      "last_4" => card["card"]["last4"],
                      "user_id" => "Recurring Charge",
                      "organization_id" => organization.id,
                      "payment_id" => payment_intent["id"],
                    }

                    with {:ok, %DcPurchase{} = dc_purchase } <- DcPurchases.create_dc_purchase_update_org(attrs, organization) do
                      organization = Organizations.get_organization!(organization.id)

                      ConsoleWeb.Endpoint.broadcast("graphql:dc_purchases_table", "graphql:dc_purchases_table:#{organization.id}:update_dc_table", %{})
                      ConsoleWeb.Endpoint.broadcast("graphql:dc_index", "graphql:dc_index:#{organization.id}:update_dc", %{})
                      broadcast_packet_purchaser_refill_dc_balance(organization)

                      Organizations.get_administrators(organization)
                      |> Enum.each(fn administrator ->
                        Email.dc_top_up_alert_email(organization, dc_purchase, administrator.email)
                        |> Mailer.deliver_later()
                      end)
                    end
                end
              end
            end
        end
    end
  end

  def broadcast_packet_purchaser_refill_dc_balance(%Organization{} = organization) do
    if organization.dc_balance > 0 do
      NetIds.get_all_for_organization(organization.id) |> Enum.map(fn net_id ->
        if net_id.active do
          ConsoleWeb.Endpoint.broadcast("net_id:all", "net_id:all:keep_purchasing", %{ net_ids: [net_id.value]})
        end
      end)
    end
  end
end
