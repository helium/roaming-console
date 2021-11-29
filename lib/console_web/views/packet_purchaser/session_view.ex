defmodule ConsoleWeb.PacketPurchaser.SessionView do
  use ConsoleWeb, :view

  def render("show.json", %{jwt: jwt}) do
    %{
      jwt: jwt
    }
  end
end
