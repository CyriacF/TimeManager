defmodule TimeManagerWeb.UserController do
  use TimeManagerWeb, :controller
  use PhoenixSwagger

  alias TimeManager.Accounts
  alias TimeManager.Accounts.User
  alias TimeManagerWeb.Plugs.AuthorizeManager

  plug AuthorizeManager when action in [ :update,:create, :delete]

  # Définitions Swagger
  def swagger_definitions do
    %{
      User: swagger_schema do
        title "Utilisateur"
        description "Un utilisateur de l'application"

        properties do
          id :integer, "ID de l'utilisateur", required: true
          username :string, "Nom d'utilisateur", required: true
          email :string, "Adresse email", required: true
          inserted_at :string, "Date de création", format: "date-time"
          updated_at :string, "Date de mise à jour", format: "date-time"
        end

        example %{
          id: 1,
          username: "johndoe",
          email: "johndoe@example.com",
          inserted_at: "2023-01-01T12:00:00Z",
          updated_at: "2023-01-02T12:00:00Z"
        }
      end,

      CreateUserParams: swagger_schema do
        title "Paramètres de création d'utilisateur"
        description "Paramètres requis pour créer un utilisateur"

        properties do
          username :string, "Nom d'utilisateur", required: true
          email :string, "Adresse email", required: true
          password :string, "Mot de passe", required: true
        end

        required [:username, :email, :password]
      end,

      UpdateUserParams: swagger_schema do
        title "Paramètres de mise à jour d'utilisateur"
        description "Paramètres pour mettre à jour un utilisateur existant"

        properties do
          username :string, "Nom d'utilisateur"
          email :string, "Adresse email"
          password :string, "Mot de passe"
        end
      end
    }
  end

  # Chemins Swagger
  swagger_path :index do
    get "/users"
    summary "Liste des utilisateurs"
    description "Récupère la liste de tous les utilisateurs"
    security [%{BearerAuth: []}]
    produces "application/json"
    parameters do
      filter :query, :string, "Filtrer par certains critères", required: false
    end
    response 200, "Liste des utilisateurs", Schema.array(:User)
  end

  swagger_path :show do
    get "/users/{id}"
    summary "Récupérer un utilisateur spécifique"
    description "Récupère un utilisateur spécifique par son ID"
    produces "application/json"
    security [%{BearerAuth: []}]
    parameters do
      id :path, :integer, "ID de l'utilisateur", required: true
    end
    response 200, "Utilisateur trouvé", Schema.ref(:User)
    response 404, "Utilisateur non trouvé"
  end

  swagger_path :create do
    post "/users"
    summary "Créer un nouvel utilisateur"
    description "Crée un nouvel utilisateur avec un nom d'utilisateur, un email et un mot de passe"
    consumes "application/json"
    security [%{BearerAuth: []}]
    produces "application/json"
    parameters do
      user :body, Schema.ref(:CreateUserParams), "Paramètres pour créer un utilisateur", required: true
    end
    response 201, "Utilisateur créé avec succès", Schema.ref(:User)
    response 422, "Paramètres invalides"
  end

  swagger_path :update do
    put "/users/{id}"
    summary "Mettre à jour un utilisateur existant"
    description "Met à jour un utilisateur existant par son ID"
    consumes "application/json"
    security [%{BearerAuth: []}]
    produces "application/json"
    parameters do
      id :path, :integer, "ID de l'utilisateur", required: true
      user :body, Schema.ref(:UpdateUserParams), "Paramètres pour mettre à jour un utilisateur", required: true
    end
    response 200, "Utilisateur mis à jour avec succès", Schema.ref(:User)
    response 404, "Utilisateur non trouvé"
    response 422, "Paramètres invalides"
  end



  swagger_path :upload_photo do
    post "/users/{id}/photo"
    summary "Uploader une photo de profil"
    description "Uploader une photo de profil pour un utilisateur"
    consumes "multipart/form-data"
    security [%{BearerAuth: []}]
    parameters do
      id :path, :integer, "ID de l'utilisateur", required: true
      photo :formData, :file, "Fichier image à uploader (JPEG/PNG)"
    end
    response 200, "Photo uploadée avec succès"
    response 400, "Erreur de validation"
  end

  swagger_path :get_me do
    get "/me"
    summary "Obtenir les informations de l'utilisateur connecté"
    description "Récupère les informations de l'utilisateur actuellement connecté via JWT"
    produces "application/json"

    security [%{BearerAuth: []}]  # Route sécurisée par JWT

    response 200, "Informations de l'utilisateur", Schema.ref(:User)
    response 401, "Non authentifié"
  end

  swagger_path :update_me do
    put "/me"
    summary "Mettre à jour les informations de l'utilisateur connecté"
    description "Met à jour les informations de l'utilisateur actuellement connecté via JWT"
    consumes "application/json"
    produces "application/json"

    security [%{BearerAuth: []}]  # Route sécurisée par JWT

    parameters do
      user :body, Schema.ref(:UpdateUserParams), "Paramètres pour mettre à jour l'utilisateur", required: true
    end
    response 200, "Utilisateur mis à jour avec succès", Schema.ref(:User)
    response 422, "Paramètres invalides"
  end
# Actions du contrôleur
  # Controller Actions

  @doc """
  Liste tous les utilisateurs avec leurs équipes et équipes gérées.
  """
  def index(conn, params) do
    users = Accounts.list_users(params)

    users_json = Enum.map(users, fn user ->
      %{
        id: user.id,
        username: user.username,
        email: user.email,
        is_manager: user.is_manager,
        is_director: user.is_director,
        team: build_team(user.team),
        managed_teams: build_managed_teams(user),
        inserted_at: user.inserted_at,
        updated_at: user.updated_at
      }
    end)

    json(conn, users_json)
  end

  @doc """
  Affiche un utilisateur spécifique avec ses équipes et équipes gérées.
  """
  def show(conn, %{"id" => id}) do
    try do
      user = Accounts.get_user!(id)

      user_json = %{
        id: user.id,
        username: user.username,
        email: user.email,
        is_manager: user.is_manager,
        is_director: user.is_director,
        team: build_team(user.team),
        managed_teams: build_managed_teams(user),
        inserted_at: user.inserted_at,
        updated_at: user.updated_at
      }

      json(conn, user_json)
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Utilisateur non trouvé"})
    end
  end

  @doc """
  Crée un nouvel utilisateur.
  """
  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, %User{} = user} ->
        # Précharger les associations pour la réponse
        user = Accounts.get_user!(user.id)

        user_json = %{
          id: user.id,
          username: user.username,
          email: user.email,
          is_manager: user.is_manager,
          is_director: user.is_director,
          team: build_team(user.team),
          managed_teams: build_managed_teams(user),
          inserted_at: user.inserted_at,
          updated_at: user.updated_at
        }

        conn
        |> put_status(:created)
        |> json(user_json)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: traverse_errors(changeset)})
    end
  end

  @doc """
  Met à jour un utilisateur spécifique.
  """
  def update(conn, %{"id" => id, "user" => user_params}) do
    try do
      user = Accounts.get_user!(id)

      case Accounts.update_user(user, user_params) do
        {:ok, %User{} = updated_user} ->
          # Précharger les associations pour la réponse
          updated_user = Accounts.get_user!(updated_user.id)

          user_json = %{
            id: updated_user.id,
            username: updated_user.username,
            email: updated_user.email,
            is_manager: updated_user.is_manager,
            is_director: updated_user.is_director,
            team: build_team(updated_user.team),
            managed_teams: build_managed_teams(updated_user),
            inserted_at: updated_user.inserted_at,
            updated_at: updated_user.updated_at
          }

          json(conn, user_json)

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: traverse_errors(changeset)})
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Utilisateur non trouvé"})
    end
  end

  @doc """
  Supprime un utilisateur spécifique.
  """
  def delete(conn, %{"id" => id}) do
    try do
      user = Accounts.get_user!(id)

      case Accounts.delete_user(user) do
        {:ok, %User{}} ->
          send_resp(conn, :no_content, "")

        {:error, _reason} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: "Impossible de supprimer l'utilisateur"})
      end
    rescue
      Ecto.NoResultsError ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Utilisateur non trouvé"})
    end
  end

  @doc """
  Obtient les informations de l'utilisateur connecté.
  """
  def get_me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    if user do
      user_json = %{
        id: user.id,
        username: user.username,
        email: user.email,
        is_manager: user.is_manager,
        is_director: user.is_director,
        team: build_team(user.team),
        managed_teams: build_managed_teams(user),
        inserted_at: user.inserted_at,
        updated_at: user.updated_at
      }

      json(conn, user_json)
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "User not authenticated"})
    end
  end

  @doc """
  Met à jour les informations de l'utilisateur connecté.
  """
  def update_me(conn, %{"user" => user_params}) do
    user = Guardian.Plug.current_resource(conn)

    if user do
      # Si l'utilisateur n'est pas directeur, empêcher la modification de is_manager et is_director
      user_params =
        if user.is_director do
          user_params
        else
          Map.drop(user_params, ["is_manager", "is_director"])
        end

      case Accounts.update_user(user, user_params) do
        {:ok, %User{} = updated_user} ->
          # Précharger les associations pour la réponse
          updated_user = Accounts.get_user!(updated_user.id)

          user_json = %{
            id: updated_user.id,
            username: updated_user.username,
            email: updated_user.email,
            is_manager: updated_user.is_manager,
            is_director: updated_user.is_director,
            team: build_team(updated_user.team),
            managed_teams: build_managed_teams(updated_user),
            inserted_at: updated_user.inserted_at,
            updated_at: updated_user.updated_at
          }

          json(conn, user_json)

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: traverse_errors(changeset)})
      end
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "User not authenticated"})
    end
  end

  @doc """
  Uploade une photo de profil pour un utilisateur.
  """
  def upload_photo(conn, %{"id" => id, "photo" => %Plug.Upload{} = upload}) do
    max_size = 2 * 1024 * 1024  # Limite de 2 MB
    content_type = upload.content_type

    if content_type in ["image/jpeg", "image/png"] && File.stat!(upload.path).size <= max_size do
      {:ok, photo_binary} = File.read(upload.path)
      user = Accounts.get_user!(id)

      case Accounts.update_user(user, %{"photo_profile" => photo_binary}) do
        {:ok, updated_user} ->
          conn
          |> put_status(:ok)
          |> json(%{message: "Photo de profil mise à jour avec succès"})

        {:error, _changeset} ->
          conn
          |> put_status(:bad_request)
          |> json(%{error: "Erreur lors de la mise à jour de l'utilisateur"})
      end
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Fichier invalide ou trop volumineux"})
    end
  end

  @doc """
  Obtient la photo de profil d'un utilisateur.
  """
  def get_photo(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    if user.photo_profile != <<0>> do
      conn
      |> put_resp_content_type("image/jpeg")  # Ajustez selon le type d'image stockée
      |> send_resp(200, user.photo_profile)
    else
      conn
      |> put_status(:not_found)
      |> json(%{error: "Photo de profil non trouvée"})
    end
  end

  # Private Helper Functions

  @doc """
  Construit la représentation JSON de l'équipe d'un utilisateur.
  """
  defp build_team(nil), do: nil
  defp build_team(team) do
    %{
      id: team.id,
      name: team.name,
      manager_id: team.manager_id,
      users: build_users(team.users)
    }
  end

  @doc """
  Construit la liste des équipes gérées par un utilisateur.
  """
  defp build_managed_teams(user) do
    if user.is_manager or user.is_director do
      Enum.map(user.managed_teams, &format_team/1)
    else
      []
    end
  end

  @doc """
  Formate une équipe en une structure JSON.
  """
  defp format_team(nil), do: nil
  defp format_team(team) do
    %{
      id: team.id,
      name: team.name,
      manager_id: team.manager_id,
      users: build_users(team.users)
    }
  end

  @doc """
  Formate une liste d'utilisateurs en une structure JSON.
  """
  defp build_users(users) do
    Enum.map(users, fn user ->
      %{
        id: user.id,
        username: user.username,
        email: user.email,
        is_manager: user.is_manager,
        is_director: user.is_director,
        team_id: user.team_id
      }
    end)
  end
  @doc """
  Traverse les erreurs d'un changeset et les formate.
  """
  defp traverse_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
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

