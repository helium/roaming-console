defmodule ConsoleWeb.PacketPurchaserApiPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :console,
    module: ConsoleWeb.Guardian,
    error_handler: ConsoleWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "packet_purchaser"}
  plug Guardian.Plug.EnsureAuthenticated
  plug ConsoleWeb.Plug.VerifyPacketPurchaserSecretVersion
end
