defmodule TimeManager.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  alias TimeManager.Accounts.User

  @derive {Jason.Encoder, only: [:id, :title, :description, :status, :user_id]}
  schema "tasks" do
    field :title, :string
    field :description, :string
    field :status, :string

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :status, :user_id])
    |> validate_required([:title, :description, :status, :user_id])
    |> assoc_constraint(:user) # Assure que l'user_id est valide
  end
end
