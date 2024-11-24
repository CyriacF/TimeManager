defmodule TimeManagerWeb.TeamController do
  use TimeManagerWeb, :controller
  use PhoenixSwagger

  alias TimeManager.Accounts
  alias TimeManager.Accounts.Team
  alias TimeManager.Repo
  action_fallback TimeManagerWeb.FallbackController

  # Définitions Swagger
  def swagger_definitions do
    %{
      Team: swagger_schema do
        title "Équipe"
        description "Une équipe de l'application"

        properties do
          id :integer, "ID de l'équipe", required: true
          name :string, "Nom de l'équipe", required: true
          manager_id :integer, "ID du manager", required: true
          users Schema.array(:User), "Liste des utilisateurs dans l'équipe"
          inserted_at :string, "Date de création", format: "date-time"
          updated_at :string, "Date de mise à jour", format: "date-time"
        end

        example %{
          id: 1,
          name: "Équipe Alpha",
          manager_id: 42,
          users: [
            %{
              id: 1,
              username: "johndoe",
              email: "johndoe@example.com"
            },
            %{
              id: 2,
              username: "janedoe",
              email: "janedoe@example.com"
            }
          ],
          inserted_at: "2023-01-01T12:00:00Z",
          updated_at: "2023-01-02T12:00:00Z"
        }
      end,

      CreateTeamParams: swagger_schema do
        title "Paramètres de création d'équipe"
        description "Paramètres requis pour créer une équipe"

        properties do
          name :string, "Nom de l'équipe", required: true
          manager_id :integer, "ID du manager", required: true
        end

        required [:name, :manager_id]
      end,

      UpdateTeamParams: swagger_schema do
        title "Paramètres de mise à jour d'équipe"
        description "Paramètres pour mettre à jour une équipe existante"

        properties do
          name :string, "Nom de l'équipe"
          manager_id :integer, "ID du manager"
        end
      end
    }
  end

  # Chemins Swagger
  swagger_path :index do
    get "/teams"
    summary "Liste des équipes"
    description "Récupère la liste de toutes les équipes, optionnellement filtrée par manager"
    produces "application/json"
    security [%{BearerAuth: []}]
    parameters do
      manager_id :query, :integer, "ID du manager pour filtrer les équipes", required: false
    end
    response 200, "Liste des équipes", Schema.array(:Team)
  end

  swagger_path :show do
    get "/teams/{id}"
    summary "Récupérer une équipe spécifique"
    description "Récupère une équipe spécifique par son ID"
    produces "application/json"
    security [%{BearerAuth: []}]
    parameters do
      id :path, :integer, "ID de l'équipe", required: true
    end
    response 200, "Équipe trouvée", Schema.ref(:Team)
    response 404, "Équipe non trouvée"
  end

  swagger_path :create do
    post "/teams"
    summary "Créer une nouvelle équipe"
    description "Crée une nouvelle équipe avec un nom et un manager"
    consumes "application/json"
    produces "application/json"
    security [%{BearerAuth: []}]
    parameters do
      team :body, Schema.ref(:CreateTeamParams), "Paramètres pour créer une équipe", required: true
    end
    response 201, "Équipe créée avec succès", Schema.ref(:Team)
    response 422, "Paramètres invalides"
  end

  swagger_path :update do
    put "/teams/{id}"
    summary "Mettre à jour une équipe existante"
    description "Met à jour une équipe existante par son ID"
    consumes "application/json"
    security [%{BearerAuth: []}]
    produces "application/json"
    parameters do
      id :path, :integer, "ID de l'équipe", required: true
      team :body, Schema.ref(:UpdateTeamParams), "Paramètres pour mettre à jour une équipe", required: true
    end
    response 200, "Équipe mise à jour avec succès", Schema.ref(:Team)
    response 404, "Équipe non trouvée"
    response 422, "Paramètres invalides"
  end

  # Actions du contrôleur

  # Liste toutes les équipes ou les équipes d'un manager spécifique
  # Liste toutes les équipes d'un manager avec préchargement des utilisateurs
  def index(conn, %{"manager_id" => manager_id}) do
    teams = Accounts.list_teams_by_manager(manager_id)
            |> Repo.preload(:users)  # Précharger les utilisateurs pour chaque équipe
    json(conn, teams)
  end

  # Liste toutes les équipes sans manager_id
  def index(conn, _params) do
    teams = Accounts.list_teams()
            |> Repo.preload(:users)  # Précharger les utilisateurs ici aussi
    json(conn, teams)
  end

  # Crée une nouvelle équipe pour un manager
  def create(conn, %{"team" => team_params}) do
    with {:ok, %Team{} = team} <- Accounts.create_team(team_params) do
      team = Repo.preload(team, [:manager, :users])
      conn
      |> put_status(:created)
      |> json(team)
    else
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors_changset(changeset)})
    end
  end

  # Mise à jour d'une équipe
  def update(conn, %{"id" => id, "team" => team_params}) do
    case Accounts.get_team(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Équipe non trouvée"})

      team ->
        old_manager_id = team.manager_id

        with {:ok, %Team{} = updated_team} <- Accounts.update_team(team, team_params) do
          # Si le manager_id a changé, gérer les associations en cascade
          new_manager_id = updated_team.manager_id

          if old_manager_id != new_manager_id do
            # Optionnel: Vous pouvez ajouter des logiques supplémentaires ici si nécessaire
            :ok
          end

          updated_team = Repo.preload(updated_team, [:manager, :users])
          json(conn, updated_team)
        else
          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{errors: translate_errors_changset(changeset)})
        end
    end
  end


  # Affiche une équipe spécifique
  def show(conn, %{"id" => id}) do
    case Accounts.get_team(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Équipe non trouvée"})

      team ->
        team = Repo.preload(team, [:users])  # Précharger les utilisateurs de l'équipe
        json(conn, team)
    end
  end



  # Suppression d'une équipe (non documentée dans Swagger)
  def delete(conn, %{"id" => id}) do
    case Accounts.get_team(id) do
      nil -> {:error, :not_found}
      team ->
        with {:ok, %Team{}} <- Accounts.delete_team(team) do
          send_resp(conn, :no_content, "")
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
  defp translate_errors_changset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
