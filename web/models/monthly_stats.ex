defmodule Gt.MonthlyStats do
  use Gt.Web, :model

  schema "monthly_stats" do
    field :date, :date
    field :inout_sum, :integer, default: 0
    field :inout_num, :integer, default: 0
    field :deps_sum, :integer, default: 0
    field :deps_num, :integer, default: 0
    field :wdrs_sum, :integer, default: 0
    field :wdrs_num, :integer, default: 0
    field :depositors, :integer, default: 0
    field :first_depositors, :integer, default: 0
    field :first_deps_sum, :integer, default: 0
    field :signups, :integer, default: 0
    field :avg_dep, :float, default: 0.0
    field :avg_arpu, :float, default: 0.0
    field :avg_first_dep, :float, default: 0.0
    field :netgaming_sum, :float, default: 0.0
    field :bets_sum, :float, default: 0.0
    field :wins_sum, :float, default: 0.0
    field :bets_num, :integer, default: 0
    field :wins_num, :integer, default: 0
    field :rake_sum, :float, default: 0.0
    field :transactors, :integer, default: 0
    field :authorizations, :integer, default: 0
    field :vip_1000, :integer, default: 0
    field :vip_1500, :integer, default: 0
    field :vip_2500, :integer, default: 0
    field :vip_5000, :integer, default: 0

    belongs_to :project, Gt.Project
  end

  @required_fields ~w(date project_id)a
  @optional_fields ~w(
    inout_sum
    inout_num
    deps_sum
    deps_num
    wdrs_sum
    wdrs_num
    depositors
    first_depositors
    first_deps_sum
    signups
    avg_dep
    avg_arpu
    avg_first_dep
    netgaming_sum
    bets_sum
    wins_sum
    bets_num
    wins_num
    rake_sum
    transactors
    authorizations
    vip_1000
    vip_1500
    vip_2500
    vip_5000
  )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def by_period(query, from, to) do
    query |> where([ms], ms.date >= ^from and ms.date <= ^to)
  end

  def by_date(query, date) do
    query |> where([ms], ms.date == ^date)
  end

  def by_project(query, project_id) do
    query |> where([ms], ms.project_id == ^project_id)
  end

  def by_projects(query, project_ids) do
    query |> where([ms], ms.project_id in ^project_ids)
  end

  def dashboard_charts(query) do
    query
    |> select([ms], %{
      date: ms.date,
      inout_sum: ms.inout_sum,
      deps_sum: ms.deps_sum,
      wdrs_sum: ms.wdrs_sum,
      netgaming_sum: ms.netgaming_sum,
      rake_sum: ms.rake_sum,
      bets_sum: ms.bets_sum,
      wins_sum: ms.wins_sum
    })
  end

  def dashboard_charts(query, :total) do
    query
    |> select([ms], %{
      date: ms.date,
      inout_sum: sum(ms.inout_sum),
      deps_sum: sum(ms.deps_sum),
      wdrs_sum: sum(ms.wdrs_sum),
      netgaming_sum: fragment("sum(?) + sum(?)", ms.netgaming_sum, ms.rake_sum),
      rake_sum: sum(ms.rake_sum),
      bets_sum: sum(ms.bets_sum),
      wins_sum: sum(ms.wins_sum)
    })
    |> group_by([ms], ms.date)
    |> order_by([ms], asc: ms.date)
  end

  def monthly_chart(query) do
    query
    |> select([ms], %{
      date: ms.date,
      inout_sum: sum(ms.inout_sum),
      inout_num: sum(ms.inout_num),
      deps_sum: sum(ms.deps_sum),
      deps_num: sum(ms.deps_num),
      wdrs_sum: sum(ms.wdrs_sum),
      wdrs_num: sum(ms.wdrs_num),
      avg_dep: avg(ms.deps_sum),
      avg_first_dep: fragment("case when sum(?) > 0 then sum(?) / sum(?) else 0 end", ms.first_depositors, ms.first_deps_sum, ms.first_depositors),
      avg_arpu: fragment("avg(?)", ms.avg_arpu),
      first_depositors: sum(ms.first_depositors),
      first_deps_sum: sum(ms.first_deps_sum),
      signups: sum(ms.signups),
      netgaming_sum: sum(ms.netgaming_sum),
      bets_sum: sum(ms.bets_sum),
      bets_num: sum(ms.bets_num),
      wins_sum: sum(ms.wins_sum),
      wins_num: sum(ms.wins_num),
      rake_sum: sum(ms.rake_sum),
      authorizations: sum(ms.authorizations),
      depositors: sum(ms.depositors),
    })
    |> group_by([ms], ms.date)
    |> order_by([ms], asc: ms.date)
  end

end
