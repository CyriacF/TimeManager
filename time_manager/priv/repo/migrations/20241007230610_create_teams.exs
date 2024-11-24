defmodule TimeManager.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      add :manager_id, references(:users, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:teams, [:manager_id])
  end
end