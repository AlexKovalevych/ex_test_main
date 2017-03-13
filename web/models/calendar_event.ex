defmodule Gt.CalendarEvent do
  use Gt.Web, :model
  use Timex
  alias Gt.Auth.Permissions
  alias Gt.Project

  schema "calendar_events" do
    field :start_at, Gt.Type.DateTimeNoSec
    field :end_at, Gt.Type.DateTimeNoSec
    field :title, :string
    field :description, :string
    field :project_ids, {:array, :integer}, virtual: true

    belongs_to :user, Gt.User

    belongs_to :type, Gt.CalendarType

    many_to_many :projects, Project, join_through: "calendar_event_projects", on_delete: :delete_all, on_replace: :delete

    timestamps()
  end

  @required_fields ~w(title start_at end_at type_id user_id project_ids)a

  @optional_fields ~w(description)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_projects(params)
    |> sanitize_description(params)
  end

  defp sanitize_description(changeset, params) do
    if Map.get(params, "description", Map.get(params, :description)) do
      changeset |> change(description: HtmlSanitizeEx.html5(params["description"]))
    else
      changeset
    end
  end

  defp validate_projects(changeset, params) do
    project_ids = Map.get(params, "project_ids", Map.get(params, :project_ids))
    if project_ids do
      projects = Project
                 |> where([p], p.id in ^Enum.map(project_ids, &String.to_integer/1))
                 |> Repo.all
      changeset |> Ecto.Changeset.put_assoc(:projects, projects)
    else
      changeset
    end
  end

  def allowed_events(query, user, include_ids \\ []) do
    case include_ids do
      [] ->
        if user.is_admin do
          query
        else
          ids = Permissions.get(user.permissions, "events_list")
               |> Enum.map(&String.to_integer/1)
          by_projects(query, ids)
        end
      _ ->
        if user.is_admin do
          by_projects(query, include_ids |> Enum.map(&String.to_integer/1), :any)
        else
          allowed_ids = Permissions.get(user.permissions, "events_list")
          ids = Enum.filter(include_ids, &Enum.member?(allowed_ids, &1))
          |> Enum.map(&String.to_integer/1)
          by_projects(query, ids)
        end
    end
  end

  def by_projects(query, ids, type \\ :strict) do
    ids_query = query
                |> join(:left, [ce], cep in "calendar_event_projects", cep.calendar_event_id == ce.id)
                |> group_by([ce, cep], cep.calendar_event_id)
                |> select([ce, cep], cep.calendar_event_id)

    ids_query = case type do
      :any ->
        ids_query |> where([ce, cep], cep.project_id in ^ids)
      :strict ->
        ids_query |> having([ce, cep], fragment("array_agg(?) <@ ?", cep.project_id, ^ids))
    end

    from ce in __MODULE__,
    join: e in subquery(ids_query), on: e.calendar_event_id == ce.id
  end

end
