defmodule ConsoleWeb.Router do
  use ConsoleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug ConsoleWeb.Plug.RateLimit, ["browser_actions", 60]
    plug ConsoleWeb.Plug.CheckDomain
    plug ConsoleWeb.Plug.VerifyRemoteIpRange
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug ConsoleWeb.Plug.RateLimit, ["auth_actions", 60]
    plug ConsoleWeb.Plug.CheckDomain
    plug ConsoleWeb.Plug.VerifyRemoteIpRange
  end

  pipeline :router_api do
    plug :accepts, ["json"]
    plug ConsoleWeb.Plug.RateLimit, ["router_auth_actions", 10]
    plug ConsoleWeb.Plug.VerifyRemoteIpRange
  end

  scope "/graphql" do
    pipe_through ConsoleWeb.Plug.GraphqlPipeline

    forward "/", Absinthe.Plug, schema: ConsoleWeb.Schema
  end

  scope "/api", ConsoleWeb do
    pipe_through :api

    get "/invitations/:token", InvitationController, :get_by_token
  end

  scope "/api", ConsoleWeb do
    pipe_through ConsoleWeb.AuthApiPipeline

    post "/users", InvitationController, :accept, as: "user_join_from_invitation"
    resources "/alerts", AlertController, only: [:create, :delete, :update]
    post "/alerts/add_to_node", AlertController, :add_alert_to_node
    post "/alerts/remove_from_node", AlertController, :remove_alert_from_node
    resources "/organizations", OrganizationController, except: [:new, :edit]
    get "/mfa_enrollments", Auth0Controller, :get_enrolled_mfa
    post "/mfa_enrollments", Auth0Controller, :enroll_in_mfa
    delete "/mfa_enrollments", Auth0Controller, :disable_mfa
    resources "/invitations", InvitationController, only: [:create, :delete]
    resources "/memberships", MembershipController, only: [:update, :delete]
    resources "/api_keys", ApiKeyController, only: [:create, :delete]

    post "/data_credits/create_customer_and_charge", DataCreditController, :create_customer_id_and_charge
    post "/data_credits/create_charge", DataCreditController, :create_charge
    get "/data_credits/payment_methods", DataCreditController, :get_payment_methods
    get "/data_credits/setup_payment_method", DataCreditController, :get_setup_payment_method
    post "/data_credits/set_default_payment_method", DataCreditController, :set_default_payment_method
    post "/data_credits/remove_payment_method", DataCreditController, :remove_payment_method
    post "/data_credits/create_dc_purchase", DataCreditController, :create_dc_purchase
    post "/data_credits/set_automatic_payments", DataCreditController, :set_automatic_payments
    post "/data_credits/transfer_dc", DataCreditController, :transfer_dc
    get "/data_credits/generate_memo", DataCreditController, :generate_memo
    get "/data_credits/router_address", DataCreditController, :get_router_address
    get "/data_credits/get_hnt_price", DataCreditController, :get_hnt_price
  end

  scope "/api/router", ConsoleWeb.Router do
    pipe_through :router_api

    post "/sessions", SessionController, :create
    post "/sessions/refresh", SessionController, :refresh
  end

  scope "/api/router", ConsoleWeb.Router do
    pipe_through ConsoleWeb.RouterApiPipeline

    resources "/organizations", OrganizationController, only: [:index, :show]
    post "/organizations/burned", OrganizationController, :burned_dc
    post "/organizations/manual_update_router_dc", OrganizationController, :manual_update_router_dc
  end

  scope "/api/v1", ConsoleWeb.V1 do
    pipe_through ConsoleWeb.V1ApiPipeline

    get "/organization", OrganizationController, :show
    resources "/alerts", AlertController, only: [:create, :update, :delete]
    post "/alerts/add_to_node", AlertController, :add_alert_to_node
    post "/alerts/remove_from_node", AlertController, :remove_alert_from_node
  end

  if Mix.env == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  scope "/", ConsoleWeb do
    pipe_through :browser # Use the default browser stack

    get "/invitations/accept/:token", InvitationController, :redirect_to_register, as: "accept_invitation"
    get "/api_keys/accept/:token", ApiKeyController, :accept, as: "accept_api_key"

    get "/*path", PageController, :index
  end
end
