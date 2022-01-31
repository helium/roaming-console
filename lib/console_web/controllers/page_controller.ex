defmodule ConsoleWeb.PageController do
  use ConsoleWeb, :controller

  action_fallback ConsoleWeb.FallbackController

  def index(conn, _params) do
    main_path = conn.path_info |> List.first()
    valid_page_paths =
      [
        "join_organization",
        "terms",
        "welcome",
        "organizations",
        "users",
        "datacredits",
        "notifications",
        "profile",
        "dashboard",
        "configuration",
        "callback"
      ]

    if conn.request_path == "/" or Enum.member?(valid_page_paths, main_path) do
      render conn, "index.html"
    else
      send_resp(conn, 404, "Not Found")
    end
  end
end
