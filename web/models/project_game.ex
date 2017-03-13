defmodule Gt.ProjectGame do
  use Gt.Web, :model

  schema "project_games" do
    field :name, :string
    field :item_id, :string
    field :is_mobile, :boolean, default: false
    field :is_demo, :boolean, default: false
    field :is_risk, :boolean, default: false

    belongs_to :project, Gt.Project
  end

  @required_fields ~w(
    project_id
    name
  )a

  @optional_fields ~w(
    item_id
    is_mobile
    is_demo
    is_risk
  )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def is_risk(name) do
    Regex.match?(~r/^.+_ch$/, name)
  end

  def is_mobile(name) do
    Regex.match?(~r/^.+_mob$/, name)
  end

  #def projects(query, project_ids) when is_list(project_ids) do
    #from pg in query,
    #where: pg.project in ^project_ids
  #end
  #def projects(query, project_id) do
    #from pg in query,
    #where: pg.project == ^project_id
  #end

  def by_project(query, project_id) do
    query |> where([pg], pg.project_id == ^project_id)
  end

  def by_name(query, name) do
    query |> where([pg], pg.name == ^name)
  end

  #def limit(query, limit) do
    #from pg in query,
    #limit: ^limit
  #end

end
