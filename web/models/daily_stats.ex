defmodule Gt.DailyStats do
  use Gt.Web, :model

  schema "daily_stats" do
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
    field :bets_num, :integer, default: 0
    field :wins_sum, :float, default: 0.0
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
    bets_num
    wins_sum
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
    query |> where([ds], fragment("? between ? and ?", ds.date, ^from, ^to))
  end

  def by_project(query, project_id) do
    query |> where([ds], ds.project_id == ^project_id)
  end

  def by_projects(query, project_ids) do
    query |> where([ds], ds.project_id in ^project_ids)
  end

  def by_date(query, date) do
    query |> where([ds], ds.date == ^date)
  end

  def monthly(from, to, project_ids) do
    __MODULE__
    |> select([ds], %{
      project_id: ds.project_id,
      date: fragment("to_char(?, 'YYYY-MM-01')", ds.date),
      inout_sum: sum(ds.inout_sum),
      inout_num: sum(ds.inout_num),
      deps_sum: sum(ds.deps_sum),
      deps_num: sum(ds.deps_num),
      wdrs_sum: sum(ds.wdrs_sum),
      wdrs_num: sum(ds.wdrs_num),
      avg_dep: avg(ds.deps_sum),
      avg_first_dep: fragment("case when sum(?) > 0 then sum(?) / sum(?) else 0 end", ds.first_depositors, ds.first_deps_sum, ds.first_depositors),
      first_depositors: sum(ds.first_depositors),
      first_deps_sum: sum(ds.first_deps_sum),
      signups: sum(ds.signups),
      netgaming_sum: sum(ds.netgaming_sum),
      bets_sum: sum(ds.bets_sum),
      bets_num: sum(ds.bets_num),
      wins_sum: sum(ds.wins_sum),
      wins_num: sum(ds.wins_num),
      rake_sum: sum(ds.rake_sum),
      authorizations: sum(ds.authorizations),
      vip_1000: sum(ds.vip_1000),
      vip_1500: sum(ds.vip_1500),
      vip_2500: sum(ds.vip_2500),
      vip_5000: sum(ds.vip_5000),
    })
    |> by_period(from, to)
    |> by_projects(project_ids)
    |> group_by([ds], [ds.project_id, fragment("to_char(?, 'YYYY-MM-01')", ds.date)])
  end

  def dashboard(from, to, project_ids, group_by \\ :project) do
    query = __MODULE__
    |> by_period(from, to)
    |> by_projects(project_ids)
    case group_by do
      :project ->
        query
        |> group_by([ds], [ds.project_id])
        |> select([ds], %{
          project_id: ds.project_id,
          inout_sum: sum(ds.inout_sum),
          inout_num: sum(ds.inout_num),
          deps_sum: sum(ds.deps_sum),
          deps_num: sum(ds.deps_num),
          wdrs_sum: sum(ds.wdrs_sum),
          wdrs_num: sum(ds.wdrs_num),
          avg_dep: avg(ds.deps_sum),
          avg_first_dep: fragment("case when sum(?) > 0 then sum(?) / sum(?) else 0 end", ds.first_depositors, ds.first_deps_sum, ds.first_depositors),
          first_depositors: sum(ds.first_depositors),
          first_deps_sum: sum(ds.first_deps_sum),
          signups: sum(ds.signups),
          netgaming_sum: sum(ds.netgaming_sum),
          bets_sum: sum(ds.bets_sum),
          bets_num: sum(ds.bets_num),
          wins_sum: sum(ds.wins_sum),
          wins_num: sum(ds.wins_num),
          rake_sum: sum(ds.rake_sum),
          authorizations: sum(ds.authorizations)
        })
      :total ->
        query
        |> select([ds], %{
          inout_sum: sum(ds.inout_sum),
          inout_num: sum(ds.inout_num),
          deps_sum: sum(ds.deps_sum),
          deps_num: sum(ds.deps_num),
          wdrs_sum: sum(ds.wdrs_sum),
          wdrs_num: sum(ds.wdrs_num),
          avg_dep: avg(ds.deps_sum),
          avg_first_dep: fragment("case when sum(?) > 0 then sum(?) / sum(?) else 0 end", ds.first_depositors, ds.first_deps_sum, ds.first_depositors),
          first_depositors: sum(ds.first_depositors),
          first_deps_sum: sum(ds.first_deps_sum),
          signups: sum(ds.signups),
          netgaming_sum: sum(ds.netgaming_sum),
          bets_sum: sum(ds.bets_sum),
          bets_num: sum(ds.bets_num),
          wins_sum: sum(ds.wins_sum),
          wins_num: sum(ds.wins_num),
          rake_sum: sum(ds.rake_sum),
          authorizations: sum(ds.authorizations)
        })
    end
  end

  def dashboard_charts(query) do
    query
    |> select([ds], %{
      date: ds.date,
      inout_sum: ds.inout_sum,
      deps_sum: ds.deps_sum,
      wdrs_sum: ds.wdrs_sum,
      netgaming_sum: ds.netgaming_sum,
      rake_sum: ds.rake_sum,
      bets_sum: ds.bets_sum,
      wins_sum: ds.wins_sum
    })
    |> order_by([ds], asc: ds.date)
  end

  def dashboard_charts(query, :total) do
    query
    |> select([ds], %{
      date: ds.date,
      inout_sum: sum(ds.inout_sum),
      deps_sum: sum(ds.deps_sum),
      wdrs_sum: sum(ds.wdrs_sum),
      netgaming_sum: fragment("sum(?) + sum(?)", ds.netgaming_sum, ds.rake_sum),
      rake_sum: sum(ds.rake_sum),
      bets_sum: sum(ds.bets_sum),
      wins_sum: sum(ds.wins_sum)
    })
    |> group_by([ds], ds.date)
    |> order_by([ds], asc: ds.date)
  end

  def daily_chart(query) do
    query
    |> select([ds], %{
      date: ds.date,
      inout_sum: sum(ds.inout_sum),
      inout_num: sum(ds.inout_num),
      deps_sum: sum(ds.deps_sum),
      deps_num: sum(ds.deps_num),
      wdrs_sum: sum(ds.wdrs_sum),
      wdrs_num: sum(ds.wdrs_num),
      avg_dep: avg(ds.deps_sum),
      avg_first_dep: fragment("case when sum(?) > 0 then sum(?) / sum(?) else 0 end", ds.first_depositors, ds.first_deps_sum, ds.first_depositors),
      avg_arpu: fragment("avg(?)", ds.avg_arpu),
      first_depositors: sum(ds.first_depositors),
      first_deps_sum: sum(ds.first_deps_sum),
      signups: sum(ds.signups),
      netgaming_sum: sum(ds.netgaming_sum),
      bets_sum: sum(ds.bets_sum),
      bets_num: sum(ds.bets_num),
      wins_sum: sum(ds.wins_sum),
      wins_num: sum(ds.wins_num),
      rake_sum: sum(ds.rake_sum),
      authorizations: sum(ds.authorizations),
      depositors: sum(ds.depositors),
    })
    |> group_by([ds], ds.date)
    |> order_by([ds], asc: ds.date)
  end

end
