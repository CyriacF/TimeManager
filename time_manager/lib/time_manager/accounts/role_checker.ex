defmodule TimeManager.Accounts.RoleChecker do
  alias TimeManager.Accounts.User

  # Vérifie si l'utilisateur est un manager
  def is_manager?(%User{is_manager: true}), do: true
  def is_manager?(_), do: false

  # Vérifie si l'utilisateur est un general manager (manager sans team_id)
  def is_general_manager?(%User{is_director: true,}), do: true
  def is_general_manager?(_), do: false
end
