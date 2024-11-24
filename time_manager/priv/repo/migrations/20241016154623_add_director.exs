defmodule TimeManager.Repo.Migrations.AddDirector do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_director, :boolean, null: false
    end
  end
end
