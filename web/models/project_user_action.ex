defmodule Gt.ProjectUserAction do
  use Gt.Web, :model

  schema "user_actions" do
    field :dep1, :map
    field :dep2, :map
    field :dep3, :map
    field :dep4, :map
    field :game1, :map
    field :game2, :map
    field :game3, :map

    belongs_to :project_user, Gt.ProjectUser
  end

  @required_fields ~w(project_user_id)a

  @optional_fields ~w(dep1 dep2 dep3 dep4 game1 game2 game3)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

end
