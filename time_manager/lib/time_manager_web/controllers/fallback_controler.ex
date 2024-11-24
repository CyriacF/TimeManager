defmodule TimeManagerWeb.FallbackController do
  use TimeManagerWeb, :controller

  # Gérer les erreurs lors de la validation des changements (Ecto)
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)  # 422 Unprocessable Entity
    |> json(%{errors: translate_errors(changeset)})
  end

  # Gérer le cas où une ressource n'est pas trouvée (404)
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)  # 404 Not Found
    |> json(%{error: "Resource not found"})
  end

  # Gérer d'autres types d'erreurs si nécessaire (403, 500, etc.)
  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)  # 403 Forbidden
    |> json(%{error: "Access forbidden"})
  end

  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)  # 400 Bad Request
    |> json(%{error: "Bad request"})
  end

  def call(conn, {:error, :internal_server_error}) do
    conn
    |> put_status(:internal_server_error)  # 500 Internal Server Error
    |> json(%{error: "Internal server error"})
  end

  # Gérer l'exception Ecto.NoResultsError
  def call(conn, %Ecto.NoResultsError{}) do
    conn
    |> put_status(:not_found)  # 404 Not Found
    |> json(%{error: "Resource not found"})
  end

  # Fonction pour traduire les erreurs d'un changeset Ecto
  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg} ->
      msg
    end)
  end
end