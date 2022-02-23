defmodule ConsoleWeb.PacketController do
  use ConsoleWeb, :controller
  alias Console.Packets

  action_fallback ConsoleWeb.FallbackController

  def index(conn, _) do
    current_unix = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    unix1d = current_unix - 86400000
    packets = Packets.get_packets_per_netid(conn.assigns.current_organization.id, unix1d)

    conn
    |> put_status(:ok)
    |> render("index.json", packets: packets)
  end
end