defmodule TimeManager.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false
      add :email, :string, null: false
      timestamps()
    end

    create unique_index(:users, [:username])  # Index unique sur username
    create unique_index(:users, [:email])     # Index unique sur email
  end
end