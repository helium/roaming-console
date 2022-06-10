defmodule Console.NetIds.NetId do
  use Ecto.Schema
  import Ecto.Changeset

  alias Console.Organizations.Organization

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "net_ids" do
    field :value, :integer
    field :config, {:array, :map}
    field :active, :boolean
    field :http_headers, Console.Encrypted.Map

    belongs_to :organization, Organization
    timestamps()
  end

  @doc false
  def changeset(net_id, attrs) do
    net_id
    |> cast(attrs, [:value, :organization_id])
    |> validate_required([:value, :organization_id])
    |> unique_constraint(:value, name: :net_ids_value_index, message: "That Net ID has already been taken.")
  end

  def update_changeset(net_id, attrs) do
    net_id
    |> cast(attrs, [
      :config,
      :active,
      :http_headers
    ])
    |> check_address_update()
    |> check_port_update()
    |> check_credentials_update()
    |> check_multi_buy_update()
  end

  defp check_credentials_update(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{config: config}} ->
        invalid_credentials = Enum.any?(config, fn net_id_config ->
          join_credentials_map =
            Regex.replace(~r/([a-z0-9]+):/, Poison.encode!(net_id_config["join_credentials"]), "\"\\1\":")
            |> String.replace("'", "\"")
            |> Poison.decode!

          case is_nil(join_credentials_map) do 
            false ->
              Enum.any?(join_credentials_map, fn cred ->
                cond do
                  String.contains?(cred["dev_eui"], "*") and String.length(cred["dev_eui"]) > 1 ->
                    true
                  String.contains?(cred["app_eui"], "*") -> true
                  true -> false
                end
              end)
            _ -> false
          end
        end)

        if invalid_credentials do
          add_error(changeset, :message, "Join credentials are invalid")
        else
          changeset
        end
      _ -> changeset
    end
  end

  defp check_address_update(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{config: config}} ->
        cond do
          Enum.any?(config, fn net_id_config ->
            net_id_config["protocol"] == "udp" and String.contains?(net_id_config["address"], " ")
          end) ->
            add_error(changeset, :message, "Address cannot have spaces")
          Enum.any?(config, fn net_id_config ->
            net_id_config["protocol"] == "udp" and !String.match?(net_id_config["address"], ~r/^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?|^((http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/)
          end) ->
            add_error(changeset, :message, "Address is invalid")
          true ->
            changeset
        end
      _ -> changeset
    end
  end

  defp check_port_update(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{config: config}} ->
        cond do
          Enum.any?(config, fn net_id_config ->
            net_id_config["protocol"] == "udp" and (net_id_config["port"] < 0 or net_id_config["port"] > 65535)
          end) ->
            add_error(changeset, :message, "Port numbers range from 0 to 65535")
          true ->
            changeset
        end
      _ -> changeset
    end
  end

   defp check_multi_buy_update(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{config: config}} ->
        cond do
          Enum.any?(config, fn net_id_config ->
            net_id_config["multi_buy"] < 0
          end) ->
            add_error(changeset, :message, "Multi buy must be a positive integer")
          true ->
            changeset
        end
      _ -> changeset
    end
  end
end
