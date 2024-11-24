defmodule TimeManagerWeb.Plugs.AuthorizeManager do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]
  alias TimeManagerWeb.Auth.Guardian
  alias TimeManager.Accounts.RoleChecker

  def init(default), do: default

  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)

    if RoleChecker.is_manager?(user) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Access forbidden: Manager role required"})
      |> halt()
    end
  end
end
