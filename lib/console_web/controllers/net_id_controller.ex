defmodule ConsoleWeb.NetIdController do
  use ConsoleWeb, :controller
  # alias Console.NetIds
  # alias Console.Repo

  plug ConsoleWeb.Plug.AuthorizeAction

  action_fallback(ConsoleWeb.FallbackController)

end
