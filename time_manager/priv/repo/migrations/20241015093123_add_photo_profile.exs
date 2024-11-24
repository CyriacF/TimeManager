defmodule TimeManager.Repo.Migrations.AddPhotoProfile do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :photo_profile, :binary, null: false
    end
  end
end
