defmodule Gt.ProjectUserStat do
  use Gt.Web, :model
  use Timex

  schema "abstract table: project_user_stats" do
    field :date, :date
    field :deps, :integer, default: 0
    field :wdrs, :integer, default: 0
    field :deps_sum, :integer, default: 0
    field :wdrs_sum, :integer, default: 0

    belongs_to :project, Gt.Project

    belongs_to :project_user, Gt.ProjectUser
  end

  @required_fields ~w(date project_user_id project_id)a

  @optional_fields ~w(deps wdrs deps_sum wdrs_sum)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_assoc(:project)
    |> cast_assoc(:project_user)
    |> validate_required(@required_fields)
  end

  def deps_cumulative(project_user_id) do
    from(pus in {"user_daily_stats", __MODULE__},
      where: pus.project_user_id == ^project_user_id and pus.deps > 0,
      group_by: [pus.date, pus.deps_sum],
      select: %{"date" => pus.date, "deps_sum" => fragment("sum(deps_sum) over (order by date)")}
    )
  end

  def daily() do
    from(pus in {"user_daily_stats", __MODULE__})
  end

  def monthly() do
    from(pus in {"user_monthly_stats", __MODULE__})
  end

  def by_date(query, date) do
    query |> where([pus], pus.date == ^date)
  end

  def by_user(query, project_user_id) do
    query |> where([pus], pus.project_user_id == ^project_user_id)
  end

  def by_period(query, from, to) do
    query
    |> where([pus], pus.date >= ^from)
    |> where([pus], pus.date <= ^to)
  end

  def by_projects(query, project_ids) do
    query |> where([pus], pus.project_id in ^project_ids)
  end

  def depositors_by_period(from, to, project_ids, group_by \\ :project) do
    query = daily()
    |> by_period(from, to)
    |> by_projects(project_ids)
    case group_by do
      :project ->
        query
        |> group_by([pus], [pus.project_id])
        |> select([pus], %{
          depositors: count(fragment("distinct(CASE WHEN ? > 0 THEN ? ELSE null END)", pus.deps, pus.project_user_id)),
          transactors: count(fragment("distinct(?)", pus.project_user_id)),
          project_id: pus.project_id
        })
      :total ->
        query
        |> select([pus], %{
          depositors: count(fragment("distinct(CASE WHEN ? > 0 THEN ? ELSE null END)", pus.deps, pus.project_user_id)),
          transactors: count(fragment("distinct(?)", pus.project_user_id)),
        })
    end
  end

  def depositors_monthly(from, to, project_ids) do
    daily()
    |> by_period(from, to)
    |> by_projects(project_ids)
    |> group_by([pus], [fragment("to_char(?, 'YYYY-MM-01')", pus.date), pus.project_id])
    |> select([pus], %{
      date: fragment("to_char(?, 'YYYY-MM-01')", pus.date),
      depositors: count(fragment("distinct(CASE WHEN ? > 0 THEN ? ELSE null END)", pus.deps, pus.project_user_id)),
      transactors: count(fragment("distinct(?)", pus.project_user_id)),
      project_id: pus.project_id
    })
  end

  def total_stats(user_id) do
    monthly()
    |> select([pus], %{
      deps: sum(pus.deps),
      wdrs: sum(pus.wdrs),
      deps_sum: sum(pus.deps_sum),
      wdrs_sum: sum(pus.wdrs_sum),
    })
    |> where([pus], pus.project_user_id == ^user_id)
    |> group_by([pus], pus.project_user_id)
    |> Repo.one
  end

end
