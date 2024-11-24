defmodule TimeManagerWeb.TaskController do
  use TimeManagerWeb, :controller
  use PhoenixSwagger

  alias TimeManager.Tasks
  alias TimeManager.Tasks.Task

  action_fallback TimeManagerWeb.FallbackController

  # Définitions Swagger
  def swagger_definitions do
    %{
      Task: swagger_schema do
        title "Tâche"
        description "Une tâche assignée à un utilisateur"

        properties do
          id :integer, "ID de la tâche", required: true
          title :string, "Titre de la tâche", required: true
          description :string, "Description de la tâche"
          user_id :integer, "ID de l'utilisateur assigné", required: true
          inserted_at :string, "Date de création", format: "date-time"
          updated_at :string, "Date de mise à jour", format: "date-time"
        end

        example %{
          id: 1,
          title: "Préparer le rapport",
          description: "Préparer le rapport annuel",
          user_id: 42,
          inserted_at: "2023-01-01T12:00:00Z",
          updated_at: "2023-01-02T12:00:00Z"
        }
      end,

      CreateTaskParams: swagger_schema do
        title "Paramètres de création de tâche"
        description "Paramètres requis pour créer une tâche"

        properties do
          title :string, "Titre de la tâche", required: true
          description :string, "Description de la tâche"
        end

        required [:title]
      end,

      UpdateTaskParams: swagger_schema do
        title "Paramètres de mise à jour de tâche"
        description "Paramètres pour mettre à jour une tâche existante"

        properties do
          title :string, "Titre de la tâche"
          description :string, "Description de la tâche"
        end
      end
    }
  end

  # Chemins Swagger
  swagger_path :index do
    get "/api/tasks"
    summary "Liste des tâches"
    description "Récupère la liste de toutes les tâches, optionnellement filtrée par utilisateur"
    produces "application/json"
    security [%{BearerAuth: []}]
    parameters do
      user_id :query, :integer, "ID de l'utilisateur pour filtrer les tâches", required: false
    end
    response 200, "Liste des tâches", Schema.array(:Task)
  end

  swagger_path :show do
    get "/api/tasks/{id}"
    summary "Récupérer une tâche spécifique"
    description "Récupère une tâche spécifique par son ID"
    produces "application/json"
    security [%{BearerAuth: []}]
    parameters do
      id :path, :integer, "ID de la tâche", required: true
    end
    response 200, "Tâche trouvée", Schema.ref(:Task)
    response 404, "Tâche non trouvée"
  end

  swagger_path :create do
    post "/api/tasks/{user_id}"
    summary "Créer une nouvelle tâche"
    description "Crée une nouvelle tâche pour un utilisateur spécifique"
    consumes "application/json"
    produces "application/json"
    security [%{BearerAuth: []}]
    parameters do
      user_id :path, :integer, "ID de l'utilisateur", required: true
      task :body, Schema.ref(:CreateTaskParams), "Paramètres pour créer une tâche", required: true
    end
    response 201, "Tâche créée avec succès", Schema.ref(:Task)
    response 422, "Paramètres invalides"
  end

  swagger_path :update do
    put "/api/tasks/{id}"
    summary "Mettre à jour une tâche existante"
    description "Met à jour une tâche existante par son ID"
    consumes "application/json"
    produces "application/json"
    security [%{BearerAuth: []}]
    parameters do
      id :path, :integer, "ID de la tâche", required: true
      task :body, Schema.ref(:UpdateTaskParams), "Paramètres pour mettre à jour une tâche", required: true
    end
    response 200, "Tâche mise à jour avec succès", Schema.ref(:Task)
    response 404, "Tâche non trouvée"
    response 422, "Paramètres invalides"
  end



  # Actions du contrôleur

  # Liste toutes les tâches ou les tâches d'un utilisateur spécifique
  def index(conn, %{"user_id" => user_id}) do
    tasks = Tasks.list_tasks_by_user(user_id)
    json(conn, tasks)
  end

  def index(conn, _params) do
    tasks = Tasks.list_tasks()
    json(conn, tasks)
  end

  # Affiche une tâche spécifique
  def show(conn, %{"id" => id}) do
    case Tasks.get_task!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Tâche non trouvée"})

      task ->
        json(conn, task)
    end
  end

  # Crée une nouvelle tâche
  def create(conn, %{"user_id" => user_id, "task" => task_params}) do
    # Ajoute l'user_id dans les paramètres de la tâche
    task_params = Map.put(task_params, "user_id", user_id)

    case Tasks.create_task(task_params) do
      {:ok, %Task{} = task} ->
        conn
        |> put_status(:created)
        |> json(task)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end

  # Met à jour une tâche existante
  def update(conn, %{"id" => id, "task" => task_params}) do
    case Tasks.get_task!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Tâche non trouvée"})

      task ->
        case Tasks.update_task(task, task_params) do
          {:ok, %Task{} = task} ->
            json(conn, task)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
        end
    end
  end

  # Supprime une tâche
  def delete(conn, %{"id" => id}) do
    case Tasks.get_task!(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Tâche non trouvée"})

      task ->
        case Tasks.delete_task(task) do
          {:ok, %Task{}} ->
            send_resp(conn, :no_content, "")

          {:error, _reason} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Impossible de supprimer la tâche"})
        end
    end
  end

  # Fonction pour traduire les erreurs de validation
  defp translate_error({msg, opts}) do
    # Personnalisez cette fonction pour traduire les messages d'erreur si nécessaire
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
