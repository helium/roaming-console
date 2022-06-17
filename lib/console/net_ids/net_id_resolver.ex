defmodule Console.NetIds.NetIdResolver do
  alias Console.Repo

  def all(_, %{context: %{current_organization: current_organization}}) do
    net_ids =
      Ecto.assoc(current_organization, :net_ids)
      |> Repo.all()
      |> Enum.map(fn ni ->
        http_headers = case ni.http_headers do
          nil -> ""
          _ ->
            Jason.encode!(ni.http_headers)
        end
        Map.put(ni, :http_headers, http_headers)
      end)

    {:ok, net_ids}
  end
end