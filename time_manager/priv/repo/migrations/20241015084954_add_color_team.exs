defmodule TimeManager.Repo.Migrations.AddColorTeam do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :color, :string, null: false
    end
  end
end
