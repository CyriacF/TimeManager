defmodule TimeManager.Repo.Migrations.AddTeamIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :team_id, references(:teams, on_delete: :nilify_all)  # Lien vers la table teams
    end

    create index(:users, [:team_id])
  end
end