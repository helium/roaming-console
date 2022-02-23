defmodule ConsoleWeb.PacketView do
  use ConsoleWeb, :view
  alias ConsoleWeb.PacketView

  def render("index.json", %{packets: packets}) do
    render_many(packets, PacketView, "packet.json")
  end

  def render("packet.json", %{packet: packet}) do
    %{
      reported_at_epoch: packet.reported_at_epoch,
      net_id: packet.net_id,
    }
  end
end
