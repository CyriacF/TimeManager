defmodule TimeManager.WorkingTimes.WorkingTime do
  use Ecto.Schema
  import Ecto.Changeset

  alias TimeManager.Accounts.User
  @derive {Jason.Encoder, only: [:id, :start, :end, :user_id,:category]}
  schema "working_times" do
    field :start, :utc_datetime
    field :end, :utc_datetime
    field :category, :string, default: "Travail"
    belongs_to :user, User
    timestamps()
  end

  def changeset(working_time, attrs) do
    working_time
    |> cast(attrs, [:start, :end, :user_id, :category])
    |> validate_required([:start, :end, :user_id, :category])
  end
end