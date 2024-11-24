defmodule TimeManagerWeb.ClockController do
  use TimeManagerWeb, :controller
  use PhoenixSwagger

  # Alias pour accéder aux fonctions du module Clockings
  alias TimeManager.Clockings
  alias TimeManager.Clockings.Clock

  # Utilisation du FallbackController pour gérer les erreurs
  action_fallback TimeManagerWeb.FallbackController

  # Définitions Swagger
  def swagger_definitions do
    %{
      Clock: swagger_schema do
        title "Horloge"
        description "Enregistrement des entrées et sorties d'un utilisateur"

        properties do
          id :integer, "ID de l'horloge", required: true
          status :string, "Statut de l'horloge ('IN' ou 'OUT')", enum: ["IN", "OUT"], required: true
          time :string, "Horodatage de l'événement", format: "date-time", required: true
          user_id :integer, "ID de l'utilisateur", required: true
          inserted_at :string, "Date de création", format: "date-time"
          updated_at :string, "Date de mise à jour", format: "date-time"
        end

        example %{
          id: 1,
          status: "IN",
          time: "2023-01-01T09:00:00Z",
          user_id: 42,
          inserted_at: "2023-01-01T09:00:00Z",
          updated_at: "2023-01-01T09:00:00Z"
        }
      end
    }
  end

  # Chemins Swagger
  swagger_path :index do
    get "/clocks/{user_id}"
    summary "Liste des horloges d'un utilisateur"
    description "Récupère la liste des horloges pour un utilisateur spécifique"
    produces "application/json"
    security [%{BearerAuth: []}]
    parameters do
      user_id :path, :integer, "ID de l'utilisateur", required: true
    end
    response 200, "Liste des horloges", Schema.array(:Clock)
    response 404, "Utilisateur non trouvé"
  end

  swagger_path :create do
    post "/clocks/{user_id}"
    summary "Créer une nouvelle horloge pour un utilisateur"
    description "Crée une nouvelle horloge (entrée ou sortie) pour un utilisateur spécifique"
    consumes "application/json"
    produces "application/json"
    security [%{BearerAuth: []}]
    parameters do
      user_id :path, :integer, "ID de l'utilisateur", required: true
    end
    response 201, "Horloge créée avec succès", Schema.ref(:Clock)
    response 422, "Paramètres invalides"
  end

  # Actions du contrôleur

  # Action pour récupérer les horloges d'un utilisateur
  def index(conn, %{"user_id" => user_id}) do
    case Clockings.get_clocks_by_user(user_id) do
      [] ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Aucune horloge trouvée pour cet utilisateur"})

      clocks ->
        json(conn, clocks)
    end
  end

  def index_me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    if user do
      case Clockings.get_clocks_by_user(user.id) do
        [] ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Aucune horloge trouvée pour cet utilisateur"})

        clocks ->
          json(conn, clocks)
      end
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "User not authenticated"})
    end
  end
  # Action pour créer une nouvelle horloge pour un utilisateur
  def create(conn, %{"user_id" => user_id}) do
    # Détermination du statut de l'horloge
    status = Clockings.determine_status(user_id)
    # Paramètres de l'horloge incluant l'user_id, le statut et l'heure actuelle
    clock_params = %{"user_id" => user_id, "status" => status, "time" => DateTime.utc_now()}

    # Création de l'horloge et envoi de la réponse JSON
    case Clockings.create_clock(clock_params) do
      {:ok, %Clock{} = clock} ->
        conn
        |> put_status(:created)
        |> json(clock)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
    end
  end
  def create_me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    if user do
      # Déterminer le statut de l'horloge (par exemple, clock-in ou clock-out)
      status = Clockings.determine_status(user.id)

      # Paramètres de l'horloge incluant l'user_id, le statut et l'heure actuelle
      clock_params = %{
        "user_id" => user.id,
        "status" => status,
        "time" => DateTime.utc_now()
      }

      # Création de l'horloge et envoi de la réponse JSON
      case Clockings.create_clock(clock_params) do
        {:ok, %Clock{} = clock} ->
          conn
          |> put_status(:created)
          |> json(clock)

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
      end
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "User not authenticated"})
    end
  end
  def create_with_state(conn, %{"user_id" => user_id, "time" => time, "status" => status}) do
    clock_params = %{"user_id" => user_id, "time" => time, "status" => status}

    case Clockings.create_clock(clock_params) do
      {:ok, %Clock{} = clock} ->
        conn
        |> put_status(:created)
        |> json(clock)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)})
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
