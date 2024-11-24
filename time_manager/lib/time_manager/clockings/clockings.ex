defmodule TimeManager.Clockings do
  import Ecto.Query, warn: false
  alias TimeManager.Repo

  # Alias pour accèder aux fonctions du module Clock
  alias TimeManager.Clockings.Clock

  # Fonction pour récupèrer les horloges d'un utilisateur
  def get_clocks_by_user(user_id) do
    # Requête pour obtenir les horloges par user_id
    from(c in Clock, where: c.user_id == ^user_id)
    |> Repo.all()
  end

  # Fonction pour lister les horloges d'un utilisateur
  def list_clocks(user_id) do
    # Requête pour obtenir les horloges par user_id
    from(c in Clock, where: c.user_id == ^user_id)
    |> Repo.all()
  end

  # Fonction pour créer une nouvelle horloge
  def create_clock(attrs \\ %{}) do
    # Création de l'horloge avec les attributs fournis
    %Clock{}
    |> Clock.changeset(attrs)
    |> Repo.insert()
  end

  # Fonction pour déterminer le statut de l'horloge
  def determine_status(user_id) do
    # Requête pour obtenir la dernière horloge par user_id
    last_clock =
      from(c in Clock,
        where: c.user_id == ^user_id,
        order_by: [desc: c.time],
        limit: 1
      )
      |> Repo.one()

    # Détermination du statut basé sur la dernière horloge
    case last_clock do
      nil -> true  # Si aucune horloge précédente, c'est un clock in
      %Clock{status: status} -> !status  # Inverser le statut précédent
    end
  end
end