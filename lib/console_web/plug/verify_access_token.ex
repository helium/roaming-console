defmodule ConsoleWeb.Plug.VerifyAccessToken do
  require Logger
  import Plug.Conn
  @access_token_decoder Application.get_env(:console, :access_token_decoder)

  def init(default), do: default

  def call(conn, _default) do
    auth_header = conn |> get_req_header("authorization")

    cond do
      auth_header == nil or List.first(auth_header) == nil ->
        conn
          |> send_resp(
            :forbidden,
            Poison.encode!(%{
              type: "forbidden",
              errors: ["Authorization header is missing"]
            })
          )
          |> halt()
      true ->
        token =
          conn
          |> get_req_header("authorization")
          |> List.first()
          |> String.replace("Bearer ", "")

        case ConsoleWeb.Guardian.decode_and_verify(token) do
          {:ok, %{ "typ" => "magic-auth-session", "sub" => user_id, "email" => email }} ->
            conn
              |> assign(:user_id, user_id)
              |> assign(:email, email)
          _ ->
            conn
            |> send_resp(
              :forbidden,
              Poison.encode!(%{
                type: "forbidden",
                errors: ["Could not validate your credentials"]
              })
            )
            |> halt()
        end
    end
  end
end
