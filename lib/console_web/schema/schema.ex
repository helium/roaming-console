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

  object :net_id do
    field :id, :id
    field :value, :integer
    field :config, :json
    field :http_headers, type: :string
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
    field :total_dc, :integer
    field :total_packets, :integer
    field :packets_last_30d, :integer
    field :dc_last_30d, :integer
    field :net_ids, list_of(:net_id)
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

  object :alerts_setting do
    field :config, :json
  end

  object :packets_per_hour do
    field :packets_per_hour, :json
    field :packets_last_1d, :integer
    field :dc_last_1d, :integer
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

    field :all_organizations, list_of(:organization) do
      resolve &Console.Organizations.OrganizationResolver.all/2
    end

    field :api_keys, list_of(:api_key) do
      resolve &Console.ApiKeys.ApiKeyResolver.all/2
    end

    paginated field :dc_purchases, :paginated_dc_purchases do
      resolve(&Console.DcPurchases.DcPurchaseResolver.paginate/2)
    end

    field :alerts_setting, :alerts_setting do
      resolve(&Console.Alerts.AlertResolver.find/2)
    end

    field :packets, :packets_per_hour do
      resolve &Console.Packets.PacketResolver.get_packets/2
    end

    field :all_net_ids, list_of(:net_id) do
      resolve &Console.NetIds.NetIdResolver.all/2
    end
  end
end
