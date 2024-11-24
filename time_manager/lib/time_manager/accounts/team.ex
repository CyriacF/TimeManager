defmodule TimeManager.Accounts.Team do
  use Ecto.Schema
  import Ecto.Changeset

  alias TimeManager.Accounts.User

  @derive {Jason.Encoder, only: [:id, :name, :manager_id,:users]}
  schema "teams" do
    field :name, :string
    field :color, :string, default: "#A7E8BD"  # Ajout de la couleur
    belongs_to :manager, User, foreign_key: :manager_id  # Un manager
    has_many :users, User  # Les utilisateurs de l'équipe

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :manager_id,:color])
    |> validate_required([:name, :manager_id])
    |> assoc_constraint(:manager)
    |> validate_manager_role()
    |> foreign_key_constraint(:manager_id, name: "teams_manager_id_fkey")
  end

  defp validate_manager_role(changeset) do
    manager_id = get_field(changeset, :manager_id)

    if manager_id do
      manager = TimeManager.Repo.get(User, manager_id)

      if manager && (manager.is_manager || manager.is_director) do
        changeset
      else
        add_error(changeset, :manager_id, "doit appartenir à un utilisateur ayant le rôle de manager ou de directeur")
      end
    else
      changeset
    end
  end
end