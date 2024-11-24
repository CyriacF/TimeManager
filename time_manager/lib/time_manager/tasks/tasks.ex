defmodule TimeManager.Tasks do
  import Ecto.Query, warn: false
  alias TimeManager.Repo

  alias TimeManager.Tasks.Task

  def list_tasks do
    Repo.all(Task)
  end

  def get_task!(id) do
    Task
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  # Fonction pour lister les tâches par utilisateur
  def list_tasks_by_user(user_id) do
    Task
    |> where(user_id: ^user_id)
    |> Repo.all()
  end
end
