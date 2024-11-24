defmodule TimeManagerWeb.AuthErrorHandler do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  @doc """
  Handles authentication errors. It returns a 401 status and a JSON error message.
  """
  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Authentication required"})
    |> halt()
  end
end
