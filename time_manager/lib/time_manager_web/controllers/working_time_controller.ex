defmodule TimeManagerWeb.WorkingTimeController do
  use TimeManagerWeb, :controller
  use PhoenixSwagger

  # Alias pour accéder aux fonctions du module WorkingTimes
  alias TimeManager.WorkingTimes
  alias TimeManager.WorkingTimes.WorkingTime

  # Utilisation du FallbackController pour gérer les erreurs
  action_fallback TimeManagerWeb.FallbackController

  # Définitions Swagger
  def swagger_definitions do
    %{
      WorkingTime: swagger_schema do
        title "Temps de Travail"
        description "Un enregistrement du temps de travail d'un utilisateur"

        properties do
          id :integer, "ID du temps de travail", required: true
          start_time :string, "Heure de début", format: "date-time", required: true
          end_time :string, "Heure de fin", format: "date-time", required: true
          user_id :integer, "ID de l'utilisateur", required: true
          inserted_at :string, "Date de création", format: "date-time"
          updated_at :string, "Date de mise à jour", format: "date-time"
        end

        example %{
          id: 1,
          start_time: "2023-01-01T09:00:00Z",
          end_time: "2023-01-01T17:00:00Z",
          user_id: 42,
          inserted_at: "2023-01-01T09:00:00Z",
          updated_at: "2023-01-01T17:00:00Z"
        }
      end,

      CreateWorkingTimeParams: swagger_schema do
        title "Paramètres de création de temps de travail"
        description "Paramètres requis pour créer un temps de travail"

        properties do
          start_time :string, "Heure de début", format: "date-time", required: true
          end_time :string, "Heure de fin", format: "date-time", required: true
        end

        required [:start_time, :end_time]
      end,

      UpdateWorkingTimeParams: swagger_schema do
        title "Paramètres de mise à jour de temps de travail"
        description "Paramètres pour mettre à jour un temps de travail existant"

        properties do
          start_time :string, "Heure de début", format: "date-time"
          end_time :string, "Heure de fin", format: "date-time"
        end
      end
    }
  end

  # Chemins Swagger
  swagger_path :index do
    get "/workingtime/{user_id}"
    summary "Liste des temps de travail d'un utilisateur"
    description "Récupère la liste des temps de travail pour un utilisateur spécifique, optionnellement filtrée par date de début et de fin"
    produces "application/json"
    parameters do
      user_id :path, :integer, "ID de l'utilisateur", required: true
      start :query, :string, "Date de début au format ISO8601", format: "date-time", required: false
      end_time :query, :string, "Date de fin au format ISO8601", format: "date-time", required: false
    end
    response 200, "Liste des temps de travail", Schema.array(:WorkingTime)
  end

  swagger_path :show do
    get "/workingtime/{user_id}/{id}"
    summary "Récupérer un temps de travail spécifique"
    description "Récupère un temps de travail spécifique par son ID pour un utilisateur donné"
    produces "application/json"
    parameters do
      user_id :path, :integer, "ID de l'utilisateur", required: true
      id :path, :integer, "ID du temps de travail", required: true
    end
    response 200, "Temps de travail trouvé", Schema.ref(:WorkingTime)
    response 404, "Temps de travail non trouvé"
  end

  swagger_path :create do
    post "/workingtime/{user_id}"
    summary "Créer un nouveau temps de travail"
    description "Crée un nouveau temps de travail pour un utilisateur spécifique"
    consumes "application/json"
    produces "application/json"
    parameters do
      user_id :path, :integer, "ID de l'utilisateur", required: true
      working_time :body, Schema.ref(:CreateWorkingTimeParams), "Paramètres pour créer un temps de travail", required: true
    end
    response 201, "Temps de travail créé avec succès", Schema.ref(:WorkingTime)
    response 422, "Paramètres invalides"
  end

  swagger_path :update do
    put "/workingtime/{id}"
    summary "Mettre à jour un temps de travail existant"
    description "Met à jour un temps de travail existant par son ID"
    consumes "application/json"
    produces "application/json"
    parameters do
      id :path, :integer, "ID du temps de travail", required: true
      working_time :body, Schema.ref(:UpdateWorkingTimeParams), "Paramètres pour mettre à jour un temps de travail", required: true
    end
    response 200, "Temps de travail mis à jour avec succès", Schema.ref(:WorkingTime)
    response 404, "Temps de travail non trouvé"
    response 422, "Paramètres invalides"
  end


  # Actions du contrôleur

  def index(conn, %{"user_id" => user_id} = params) do
    # Définir les valeurs par défaut pour start_time et end_time si elles ne sont pas fournies
    start_time = Map.get(params, "start", "1970-01-01T00:00:00Z")
    end_time = Map.get(params, "end", "3000-01-01T00:00:00Z")

    working_times = WorkingTimes.get_working_times_by_user(user_id, start_time, end_time)
    json(conn, working_times)
  end

  # Action pour récupérer un temps de travail spécifique d'un utilisateur
  def show(conn, %{"user_id" => user_id, "id" => id}) do
    case WorkingTimes.get_working_time!(user_id, id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Temps de travail non trouvé"})

      working_time ->
        json(conn, working_time)
    end
  end

  # Action pour créer un nouveau temps de travail pour un utilisateur
  def create(conn, %{"user_id" => user_id, "working_time" => working_time_params}) do
    # Ajout de l'user_id aux paramètres du temps de travail
    working_time_params = Map.put(working_time_params, "user_id", user_id)

    # Création du temps de travail et envoi de la réponse JSON
    case WorkingTimes.create_working_time(working_time_params) do
      {:ok, %WorkingTime{} = working_time} ->
        conn
        |> put_status(:created)
        |> json(working_time)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  # Action pour mettre à jour un temps de travail existant
  def update(conn, %{"id" => id, "working_time" => working_time_params}) do
    case WorkingTimes.get_working_time!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Temps de travail non trouvé"})

      working_time ->
        case WorkingTimes.update_working_time(working_time, working_time_params) do
          {:ok, %WorkingTime{} = updated_working_time} ->
            json(conn, updated_working_time)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
        end
    end
  end

  # Action pour supprimer un temps de travail existant
  def delete(conn, %{"id" => id}) do
    case WorkingTimes.get_working_time!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Temps de travail non trouvé"})

      working_time ->
        case WorkingTimes.delete_working_time(working_time) do
          {:ok, %WorkingTime{}} ->
            send_resp(conn, :no_content, "")

          {:error, _reason} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Impossible de supprimer le temps de travail"})
        end
    end
  end

  # Fonction pour traduire les erreurs de validation
  defp translate_error({msg, opts}) do
    # Vous pouvez personnaliser cette fonction pour traduire les messages d'erreur
    # Par exemple, utiliser Gettext pour la localisation
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
