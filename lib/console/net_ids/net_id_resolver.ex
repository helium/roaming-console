defmodule Console.NetIds.NetIdResolver do
  alias Console.Repo

  def all(_, %{context: %{current_organization: current_organization}}) do
    net_ids =
      Ecto.assoc(current_organization, :net_ids)
      |> Repo.all()
      |> Enum.map(fn ni ->
        Map.put(ni, :http_auth_header, ni.http_headers["auth"])
      end)

    {:ok, net_ids}
  end
end