  defmodule TimeManager.Accounts do
    import Ecto.Query, warn: false
    alias TimeManager.Repo
    alias TimeManager.Clockings.{Clock, Clockings}
    alias TimeManager.WorkingTimes.{WorkingTime, WorkingTimes}
    alias TimeManager.Accounts.{Team, User}

    def list_users(params \\ %{}) do
      User
      |> build_user_query(params)
      |> Repo.all()
      |> Repo.preload([team: [:users], managed_teams: [:users]])
    end


    defp build_user_query(query, params) do
      query
      |> maybe_filter_by_email(params)
      |> maybe_filter_by_username(params)
    end

    defp maybe_filter_by_email(query, %{"email" => email}) when not is_nil(email) do
      from u in query, where: u.email == ^email
    end
    defp maybe_filter_by_email(query, _), do: query

    defp maybe_filter_by_username(query, %{"username" => username}) when not is_nil(username) do
      from u in query, where: u.username == ^username
    end
    defp maybe_filter_by_username(query, _), do: query


    def get_user!(id) do
      User
      |> Repo.get!(id)
      |> Repo.preload([team: [:users], managed_teams: [:users]])
    end

    def create_user(attrs \\ %{}) do
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()
    end

    def update_user(%User{} = user, attrs) do
      user
      |> User.changeset(attrs)
      |> Repo.update()
    end

    def delete_user(%User{} = user) do
      Repo.delete(user)
    end

    # Créer une nouvelle équipe
    def create_team(attrs \\ %{}) do
      %Team{}
      |> Team.changeset(attrs)
      |> Repo.insert()
    end


    # Lister toutes les équipes
    def list_teams do
      Repo.all(Team)
      |> Repo.preload([:manager, :users])
    end

    # Lister les équipes d'un manager
    def list_teams_by_manager(manager_id) do
      Repo.all(from t in Team, where: t.manager_id == ^manager_id)
      |> Repo.preload([:manager, :users])
    end


    # Obtenir une équipe spécifique
    def get_team(id), do: Repo.get(Team, id) |> Repo.preload([:manager, :users])


    # Mettre à jour une équipe
    def update_team(%Team{} = team, attrs) do
      team
      |> Team.changeset(attrs)
      |> Repo.update()
    end

    # Supprimer une équipe
    def delete_team(%Team{} = team) do
      Repo.delete(team)
    end


      def create_clock(params) do
        %Clock{}
        |> Clock.changeset(params)
        |> Repo.insert()
      end

      def create_working_time(params) do
        %WorkingTime{}
        |> WorkingTime.changeset(params)
        |> Repo.insert()
      end

    def register_user(attrs \\ %{}) do
      %User{}
      |> User.registration_changeset(attrs)
      |> Repo.insert()
    end
    def authenticate_user(email, password) do
      user = Repo.get_by(User, email: email)

      cond do
        user && User.valid_password?(user, password) ->
          {:ok, token, _claims} = TimeManagerWeb.Auth.Guardian.encode_and_sign(user)
          {:ok, user, token}
        true ->
          {:error, "Invalid credentials"}
      end
    end
    def change_password(user, password, new_password_params) do
      if User.valid_password?(user, password) do
        user
        |> User.password_changeset(new_password_params, hash_password: true)
        |> Repo.update()
      else
        {:error, "Current password is incorrect"}
      end
    end
  end