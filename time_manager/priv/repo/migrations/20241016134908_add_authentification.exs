defmodule TimeManager.Repo.Migrations.AddAuthentification do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :hashed_password, :string, null: false
    end
  end
end
