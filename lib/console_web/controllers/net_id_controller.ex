defmodule ConsoleWeb.NetIdController do
  use ConsoleWeb, :controller
  alias Console.NetIds
  alias Console.Repo

  plug ConsoleWeb.Plug.AuthorizeAction

  action_fallback(ConsoleWeb.FallbackController)

  def create(conn, %{"net_ids" => net_ids}) do
    current_organization = conn.assigns.current_organization

    net_ids =
      String.split(net_ids, ",")
      |> Enum.map(fn str -> String.trim(str) end)

    result = Repo.transaction(fn ->
      Enum.map(net_ids, fn value ->
        NetIds.create_net_id!(%{ "value" => value}, current_organization)
      end)
    end)

    with {:ok, _} <- result do
      conn
      |> put_resp_header("message", "Net IDs set for current organization")
      |> send_resp(:no_content, "")
    end
  end
end
