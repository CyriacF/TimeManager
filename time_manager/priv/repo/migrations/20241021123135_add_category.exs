defmodule TimeManager.Repo.Migrations.AddCategory do
  use Ecto.Migration

  def change do
    alter table(:working_times) do
      add :category, :string, default: "Travail", null: false
    end
  end
end
