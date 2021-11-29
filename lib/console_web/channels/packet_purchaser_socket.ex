defmodule ConsoleWeb.PacketPurchaserSocket do
  use Phoenix.Socket

  channel("organization:*", ConsoleWeb.OrganizationChannel)

  def connect(%{"token" => token}, socket) do
    case ConsoleWeb.Guardian.decode_and_verify(token) do
      {:ok, %{ "typ" => "packet_purchaser"}} ->
        {:ok, socket}
      {:error, _} ->
        :error
    end
  end

  def connect(_params, _socket) do
    :error
  end

  def id(_socket), do: nil
end
