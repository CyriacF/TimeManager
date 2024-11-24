defmodule TimeManagerWeb.SwaggerController do
  use TimeManagerWeb, :controller

  def index(conn, _params) do
    swagger_spec = File.read!("priv/static/swagger.json")
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, swagger_spec)
  end
end