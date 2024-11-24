defmodule TimeManagerWeb.Auth.Guardian do
  use Guardian, otp_app: :time_manager

  alias TimeManager.Accounts

  # Encode le user_id dans le token JWT
  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  # Décoder le token JWT pour récupérer l'utilisateur
  def resource_from_claims(claims) do
    id = claims["sub"]
    user = Accounts.get_user!(id)
    {:ok, user}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end
end
