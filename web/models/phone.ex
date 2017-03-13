defmodule Gt.Phone do
  use Gt.Web, :model

  schema "phones" do
    field :number, :string
    field :type, :integer
    field :valid, :integer
    field :manual_validation, :boolean

    belongs_to :project_user, Gt.ProjectUser
  end

  @required_fields ~w(number project_user_id)a

  @optional_fields ~w(type valid manual_validation)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> foreign_key_constraint(:project_user_id)
    |> validate_required(@required_fields)
  end

end
