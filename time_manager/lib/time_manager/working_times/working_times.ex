defmodule TimeManager.WorkingTimes do
  import Ecto.Query, warn: false
  alias TimeManager.Repo

  # Alias pour accèder aux fonctions du module WorkingTime
  alias TimeManager.WorkingTimes.WorkingTime

  # Fonction pour récupèrer les temps de travail d'un utilisateur entre deux dates
  def get_working_times_by_user(user_id, start_time \\ nil, end_time \\ nil) do
    # Requête pour obtenir les temps de travail par user_id
    query = from wt in WorkingTime, where: wt.user_id == ^user_id

    # Ajout des conditions de date si elles sont fournies
    query =
      if start_time && end_time do
        from wt in query,
             where: wt.start >= ^start_time and wt.end <= ^end_time
      else
        query
      end

    # Exécution de la requête et retour des résultats
    Repo.all(query)
  end

  # Fonction pour lister les temps de travail d'un utilisateur
  def list_working_times(user_id, params \\ %{}) do
    # Requête pour obtenir les temps de travail par user_id
    query = from wt in WorkingTime, where: wt.user_id == ^user_id

    # Ajout des conditions de date si elles sont fournies
    query =
      if params["start"] && params["end"] do
        from wt in query,
             where: wt.start >= ^params["start"] and wt.end <= ^params["end"]
      else
        query
      end

    # Exécution de la requête et retour des résultats
    Repo.all(query)
  end

  # Fonction pour récupèrer un temps de travail spécifique d'un utilisateur
  def get_working_time!(user_id, id) do
    # Requête pour obtenir le temps de travail par id et user_id
    Repo.get_by!(WorkingTime, id: id, user_id: user_id)
  end

  # Fonction pour récupèrer un temps de travail spécifique par id
  def get_working_time!(id), do: Repo.get!(WorkingTime, id)

  # Fonction pour créer un nouveau temps de travail
  def create_working_time(attrs \\ %{}) do
    # Création du temps de travail avec les attributs fournis
    %WorkingTime{}
    |> WorkingTime.changeset(attrs)
    |> Repo.insert()
  end

  # Fonction pour mettre à jour un temps de travail existant
  def update_working_time(%WorkingTime{} = working_time, attrs) do
    # Mise à jour du temps de travail avec les attributs fournis
    working_time
    |> WorkingTime.changeset(attrs)
    |> Repo.update()
  end

  # Fonction pour supprimer un temps de travail existant
  def delete_working_time(%WorkingTime{} = working_time) do
    # Suppression du temps de travail
    Repo.delete(working_time)
  end
end