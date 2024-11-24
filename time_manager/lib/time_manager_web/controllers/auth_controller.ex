defmodule TimeManagerWeb.AuthController do
  use TimeManagerWeb, :controller
  use PhoenixSwagger
  alias TimeManager.Accounts
  alias TimeManagerWeb.Auth.Guardian
  alias Hammer

  defp tuple_to_ip_string({a, b, c, d}) do
    "#{a}.#{b}.#{c}.#{d}"
  end

  def swagger_definitions do
    %{
      LoginParams: swagger_schema do
        title "Paramètres de connexion"
        description "Paramètres requis pour la connexion"
        properties do
          email :string, "Adresse email", required: true
          password :string, "Mot de passe", required: true
        end
        required [:email, :password]
      end,

      ChangePasswordParams: swagger_schema do
        title "Paramètres de changement de mot de passe"
        description "Paramètres pour changer le mot de passe"
        properties do
          current_password :string, "Mot de passe actuel", required: true
          new_password :string, "Nouveau mot de passe", required: true
        end
        required [:current_password, :new_password]
      end,

      MessageResponse: swagger_schema do
        title "Réponse standard"
        description "Message standard pour les réponses de succès ou d'erreur"
        properties do
          message :string, "Message de confirmation"
        end
      end
    }
  end

  # Chemins Swagger
  swagger_path :login do
    post "/auth/login"
    summary "Connexion utilisateur"
    description "Connecte un utilisateur avec son adresse email et son mot de passe"
    consumes "application/json"
    produces "application/json"
    parameters do
      login :body, Schema.ref(:LoginParams), "Paramètres pour la connexion", required: true
    end
    response 200, "Connexion réussie", Schema.ref(:MessageResponse)
    response 401, "Échec de la connexion"
    response 429, "Trop de tentatives"
  end

  swagger_path :register do
    post "/auth/register"
    summary "Enregistrement d'un nouvel utilisateur"
    description "Crée un nouvel utilisateur avec un email, un mot de passe et un nom d'utilisateur"
    consumes "application/json"
    produces "application/json"
    parameters do
      user :body, Schema.ref(:CreateUserParams), "Paramètres pour l'enregistrement", required: true
    end
    response 201, "Utilisateur créé avec succès", Schema.ref(:User)
    response 422, "Paramètres invalides"
  end

  swagger_path :change_password do
    post "/auth/change_password"
    summary "Changer le mot de passe"
    description "Permet à un utilisateur de changer son mot de passe"
    consumes "application/json"
    produces "application/json"
    parameters do
      password :body, Schema.ref(:ChangePasswordParams), "Paramètres pour changer le mot de passe", required: true
    end
    response 200, "Mot de passe changé avec succès", Schema.ref(:MessageResponse)
    response 422, "Erreur de validation"
  end

  swagger_path :logout do
    post "/auth/logout"
    summary "Déconnexion"
    description "Déconnecte un utilisateur en révoquant son token JWT"
    response 200, "Déconnexion réussie", Schema.ref(:MessageResponse)
  end

  # Action pour enregistrer un nouvel utilisateur
  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{message: "User created successfully", user: user})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset})
    end
  end

  # Action pour la connexion de l'utilisateur (générer JWT)
  def login(conn, %{"email" => email, "password" => password}) do
    # Limiter les tentatives de connexion par IP
    ip_address = tuple_to_ip_string(conn.remote_ip)
    case Hammer.check_rate("login:#{ip_address}", 60_000, 5) do
      {:allow, _count} ->
        # Si le nombre de tentatives est sous la limite, continuer
        case Accounts.authenticate_user(email, password) do
          {:ok, user, token} ->
            conn
            |> json(%{message: "Login successful", token: token, user: user})

          {:error, reason} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: reason})
        end

      {:deny, _limit} ->
        # Si la limite est atteinte, répondre avec un code 429 (Too Many Requests)
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: "Too many login attempts. Please try again later."})
    end
  end

  def change_password(conn, %{"current_password" => current_password, "new_password" => new_password}) do
    user = Guardian.Plug.current_resource(conn)

    case Accounts.change_password(user, current_password, %{"password" => new_password}) do
      {:ok, _user} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Password updated successfully"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  # Action pour la déconnexion (invalider le JWT)
  def logout(conn, _params) do
    token = Guardian.Plug.current_token(conn)

    case Guardian.revoke(token) do
      {:ok, _claims} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Logout successful"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end
end
