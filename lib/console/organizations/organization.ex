defmodule Console.Organizations.Organization do
  use Ecto.Schema
  import Ecto.Changeset
  alias Console.Helpers

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "organizations" do
    field :name, :string
    field :dc_balance, :integer
    field :stripe_customer_id, :string
    field :default_payment_id, :string
    field :automatic_charge_amount, :integer
    field :automatic_payment_method, :string
    field :dc_balance_nonce, :integer
    field :pending_automatic_purchase, :boolean
    field :active, :boolean
    field :received_free_dc, :boolean
    field :address, :string
    field :join_credentials, :string
    field :port, :integer
    field :multi_buy, :integer
    field :total_dc, :integer
    field :total_packets, :integer

    has_many :memberships, Console.Organizations.Membership, on_delete: :delete_all
    many_to_many :users, Console.Auth.User, join_through: "memberships"
    has_many :invitations, Console.Organizations.Invitation, on_delete: :delete_all
    has_many :api_keys, Console.ApiKeys.ApiKey, on_delete: :delete_all
    has_many :memos, Console.Memos.Memo, on_delete: :delete_all
    has_many :net_ids, Console.NetIds.NetId, on_delete: :delete_all
    has_one :alerts, Console.Alerts.Alert, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(organization, attrs) do
    attrs = Helpers.sanitize_attrs(attrs, ["name"])

    organization
    |> cast(attrs, [:name])
    |> validate_required(:name, message: "Organization Name is required")
    |> validate_length(:name, min: 3, message: "Organization Name must be at least 3 characters")
    |> validate_length(:name, max: 50, message: "Organization Name cannot be longer than 50 characters")
    |> check_name
  end

  @doc false
  def create_changeset(organization, attrs) do
    organization
    |> changeset(attrs)
  end

  def update_changeset(organization, attrs) do
    organization
    |> cast(attrs, [
      :stripe_customer_id,
      :default_payment_id,
      :dc_balance,
      :automatic_charge_amount,
      :automatic_payment_method,
      :dc_balance_nonce,
      :pending_automatic_purchase,
      :active,
      :received_free_dc,
      :address,
      :port,
      :multi_buy,
      :join_credentials,
      :total_dc,
      :total_packets
    ])
    |> check_address()
    |> validate_number(:port, greater_than_or_equal_to: 0, message: "Port numbers range from 0 to 65535")
    |> validate_number(:port, less_than_or_equal_to: 65535, message: "Port numbers range from 0 to 65535")
    |> validate_number(:multi_buy, greater_than_or_equal_to: 0, message: "Multi buy must be a positive integer")
    |> check_credentials_update()
  end

  defp check_name(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{name: name}} ->
        valid_name = Helpers.check_special_characters(name)
        case valid_name do
          false -> add_error(changeset, :message, "Please refrain from using special characters in the org name")
          true -> changeset
        end
      _ -> changeset
    end
  end

  defp check_credentials_update(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{join_credentials: creds}} ->
        join_credentials_map =
          Regex.replace(~r/([a-z0-9]+):/, creds, "\"\\1\":")
          |> String.replace("'", "\"")
          |> Poison.decode!
        
        invalid = Enum.any?(join_credentials_map, fn cred ->
          cond do
            String.contains?(cred["dev_eui"], "*") and String.length(cred["dev_eui"]) > 1 ->
              true
            String.contains?(cred["app_eui"], "*") -> true
            true -> false
          end
        end)

        if invalid do
          add_error(changeset, :message, "Join credentials are invalid")
        else 
          changeset
        end
      _ -> changeset
    end
  end

  defp check_address(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{address: address}} ->
        cond do
          String.contains?(address, " ") ->
            add_error(changeset, :message, "Address cannot have spaces")
          !String.match?(address, ~r/^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?|^((http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/) ->
            add_error(changeset, :message, "Address is invalid")
          true ->
            changeset
        end
      _ -> changeset
    end
  end
end
