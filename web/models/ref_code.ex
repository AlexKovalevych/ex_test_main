defmodule Gt.RefCode do
  use Gt.Web, :model

  schema "ref_codes" do
    field :date, :date
    field :code, :string

    belongs_to :project_user, Gt.ProjectUser
  end

  @required_fields ~w(project_user_id date code)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> foreign_key_constraint(:project_user_id)
    |> validate_required(@required_fields)
  end

end
