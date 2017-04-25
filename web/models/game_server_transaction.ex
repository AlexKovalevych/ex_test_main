defmodule Gt.GameServerTransaction do
  use Gt.Web, :model

  schema "game_server_transactions" do
    field :item_id, :string
    field :date, :naive_datetime
    field :sum, :integer
    field :user_sum, :integer
    field :system, :string
    field :system_id, :integer
    field :status, :string
    field :status_id, :integer
    field :pguid, :string

    belongs_to :project, Gt.Project

    timestamps()
  end

  @required_fields ~w(
    item_id
    date
    sum
    user_sum
    status
    status_id
    project_id
  )a

  @optional_fields ~w(pguid system system_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

end
