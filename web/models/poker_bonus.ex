defmodule Gt.PokerBonus do
  use Timex
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :id

  schema "poker_bonuses" do
    field :amount, :float
    field :currency, :string
    field :date, :naive_datetime
    field :type, :string

    belongs_to :project_user, Gt.ProjectUser

    belongs_to :project, Gt.Project

    timestamps()
  end

  @required_fields ~w(amount currency date project_user_id project_id)a

  @optional_fields ~w(type)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def generate_id(data) do
    data = "#{data.amount}#{data.currency}#{Timex.format!(data.date, "{ISOdate} {ISOtime}{Z:}")}#{data.type}#{data.project_user_id}"
    :crypto.hash(:sha, data) |> Base.encode16(case: :lower)
  end
end
