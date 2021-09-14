defmodule ConsoleWeb.Schema do
  use Absinthe.Schema
  use ConsoleWeb.Schema.Paginated
  import_types Absinthe.Type.Custom

  scalar :json, description: "JSON field type in postgres" do
    parse fn input ->
      case Poison.decode(input.value) do
        {:ok, result} -> {:ok, result}
        _ -> :error
      end
    end

    serialize &Poison.encode!/1
  end

  object :alert do
    field :id, :id
    field :name, :string
    field :last_triggered_at, :string
    field :node_type, :string
    field :config, :json
    field :organization_id, :id
  end

  paginated object :membership do
    field :id, :id
    field :email, :string
    field :two_factor_enabled, :boolean
    field :role, :string
    field :inserted_at, :naive_datetime
  end

  paginated object :invitation do
    field :id, :id
    field :email, :string
    field :role, :string
    field :inserted_at, :naive_datetime
  end

  paginated object :organization do
    field :id, :id
    field :name, :string
    field :inserted_at, :naive_datetime
    field :dc_balance, :integer
    field :dc_balance_nonce, :integer
    field :stripe_customer_id, :string
    field :default_payment_id, :string
    field :automatic_payment_method, :string
    field :automatic_charge_amount, :integer
    field :active, :boolean
    field :received_free_dc, :boolean
  end

  object :api_key do
    field :id, :id
    field :name, :string
    field :role, :string
    field :inserted_at, :naive_datetime
    field :user, :string
    field :active, :boolean
  end

  paginated object :dc_purchase do
    field :id, :id
    field :dc_purchased, :integer
    field :cost, :integer
    field :user_id, :string
    field :card_type, :string
    field :last_4, :string
    field :inserted_at, :naive_datetime
    field :payment_id, :string
    field :from_organization, :string
    field :to_organization, :string
  end

  query do
    paginated field :memberships, :paginated_memberships do
      resolve(&Console.Organizations.MembershipResolver.paginate/2)
    end

    paginated field :invitations, :paginated_invitations do
      resolve(&Console.Organizations.InvitationResolver.paginate/2)
    end

    paginated field :organizations, :paginated_organizations do
      resolve(&Console.Organizations.OrganizationResolver.paginate/2)
    end

    field :organization, :organization do
      arg :id, non_null(:id)
      resolve(&Console.Organizations.OrganizationResolver.find/2)
    end

    paginated field :organizations, :paginated_organizations do
      resolve(&Console.Organizations.OrganizationResolver.paginate/2)
    end

    field :all_organizations, list_of(:organization) do
      resolve &Console.Organizations.OrganizationResolver.all/2
    end

    field :api_keys, list_of(:api_key) do
      resolve &Console.ApiKeys.ApiKeyResolver.all/2
    end

    field :all_alerts, list_of(:alert) do
      resolve &Console.Alerts.AlertResolver.all/2
    end

    field :alert, :alert do
      arg :id, non_null(:id)
      resolve &Console.Alerts.AlertResolver.find/2
    end

    paginated field :dc_purchases, :paginated_dc_purchases do
      resolve(&Console.DcPurchases.DcPurchaseResolver.paginate/2)
    end
  end
end
