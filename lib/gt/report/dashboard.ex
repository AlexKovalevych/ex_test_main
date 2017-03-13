defmodule Gt.DashboardChart do
  defstruct inout_sum: 0,
            deps_sum: 0,
            wdrs_sum: 0,
            netgaming_sum: 0,
            bets_sum: 0,
            wins_sum: 0,
            rake_sum: 0,
            date: nil
end

defmodule Gt.Report.Dashboard do
  use Timex
  alias Gt.Repo
  alias Gt.Project
  alias Gt.ProjectUserStat
  alias Gt.DailyStats
  alias Gt.MonthlyStats
  import Ecto.Query
  import String, only: [to_atom: 1]

  defstruct inout_sum: 0,
            inout_num: 0,
            deps_sum: 0,
            deps_num: 0,
            wdrs_sum: 0,
            wdrs_num: 0,
            depositors: 0,
            first_depositors: 0,
            first_deps_sum: 0,
            signups: 0,
            avg_dep: 0,
            avg_arpu: 0,
            avg_first_dep: 0,
            netgaming_sum: 0,
            bets_sum: 0,
            bets_num: 0,
            wins_sum: 0,
            wins_num: 0,
            rake_sum: 0,
            transactors: 0,
            authorizations: 0

  def fetch(struct, key) when is_bitstring(key) do
    fetch(struct, to_atom(key))
  end

  def fetch(struct, key) when is_atom(key) do
    {:ok, Map.get(struct, key)}
  end

  def load_data(user) do
    settings = user.settings
    projects = Project |> where([p], p.id in ^Project.allowed(user, "dashboard_index"))
                       |> where([p], p.is_partner == ^(settings.dashboard_projects == "partner"))
                       |> Repo.all
    project_ids = Enum.map(projects, fn %Project{id: id} -> id end)
    period = Map.get(settings, :dashboard_period, "month") |> to_atom
    compare_period = Map.get(settings, :dashboard_compare_period, -1)
    metrics = Map.get(settings, :dashboard_sort, "inout_sum")
    data = get_stats(period, compare_period, project_ids, metrics)
    charts = get_charts(period, project_ids)
    %{
      stats: data.stats,
      charts: charts,
      periods: data.periods,
      monthly_chart_period: get_period(:months12),
      totals: data.totals,
      projects: Enum.into(projects, %{}, fn project -> {project.id, project} end),
      max_value: data.max_value
    }
  end

  def get_period(:month) do
    get_period(:month, -1)
  end

  def get_period(:year) do
    now = Timex.today
    current_start = now |> Timex.set(day: 1, month: 1)
    comparison_start = Timex.shift(current_start, years: -1)
    comparison_end = now |> Timex.shift(years: -1)
    {current_start, now, comparison_start, comparison_end}
  end

  def get_period(:days30) do
    now = Timex.today
    current_start = now |> Timex.shift(days: -30)
    comparison_end = current_start |> Timex.shift(days: -1)
    comparison_start = comparison_end |> Timex.shift(days: -30)
    {current_start, now, comparison_start, comparison_end}
  end

  def get_period(:months12) do
    now = Timex.today
    current_end = now |> Timex.set(day: 1)
    current_start = current_end |> Timex.shift(months: -11)
    comparison_end = current_start |> Timex.shift(months: -1)
    comparison_start = comparison_end |> Timex.shift(days: -11)
    {current_start, now, comparison_start, comparison_end}
  end

  def get_period(:month, previous_period) do
    now = Timex.today
    current_start = now |> Timex.set(day: 1)
    comparison_start = Timex.shift(current_start, months: previous_period)
    comparison_end = now |> Timex.shift(months: previous_period)
    {current_start, now, comparison_start, comparison_end}
  end

  def get_stats({current_start, current_end, comparison_start, comparison_end}, project_ids, metrics) do
    metrics = String.to_atom(metrics)

    current_depositors = ProjectUserStat.depositors_by_period(current_start, current_end, project_ids) |> Repo.all
    current_stats = DailyStats.dashboard(current_start, current_end, project_ids) |> Repo.all

    comparison_depositors = ProjectUserStat.depositors_by_period(comparison_start, comparison_end, project_ids) |> Repo.all
    comparison_stats = DailyStats.dashboard(comparison_start, comparison_end, project_ids) |> Repo.all

    current_stats = Enum.into(project_ids, %{}, fn id ->
      {id, %__MODULE__{}}
    end)
    |> set_depositors(current_depositors)
    |> set_stats(current_stats)

    comparison_stats = Enum.into(project_ids, %{}, fn id ->
      {id, %__MODULE__{}}
    end)
    |> set_depositors(comparison_depositors)
    |> set_stats(comparison_stats)

    # calculate totals
    current_depositors_total = ProjectUserStat.depositors_by_period(current_start, current_end, project_ids, :total) |> Repo.one
    current_stats_total = DailyStats.dashboard(current_start, current_end, project_ids, :total) |> Repo.one
    current_total = %__MODULE__{}
                    |> set_depositors(current_depositors_total)
                    |> set_stats(current_stats_total)

    comparison_depositors_total = ProjectUserStat.depositors_by_period(comparison_start, comparison_end, project_ids, :total) |> Repo.one
    comparison_stats_total = DailyStats.dashboard(comparison_start, comparison_end, project_ids, :total) |> Repo.one
    comparison_total = %__MODULE__{}
                    |> set_depositors(comparison_depositors_total)
                    |> set_stats(comparison_stats_total)

    [current_stats, comparison_stats] = project_ids
    |> Enum.into(%{}, fn id ->
      {id, [Enum.max(Map.values(current_stats[id])), Enum.max(Map.values(comparison_stats[id]))] |> Enum.max}
    end)
    |> Enum.reduce([current_stats, comparison_stats], fn {id, max_value}, acc ->
      if max_value == 0, do: [Map.delete(current_stats, id), Map.delete(comparison_stats, id)], else: acc
    end)

    stats = Enum.map(project_ids, fn id ->
      %{
        id: id,
        values: %{
          current: current_stats[id],
          comparison: comparison_stats[id]
        }
      }
    end)
    |> Enum.filter(fn %{values: %{current: current, comparison: comparison}} ->
      value = [Map.get(current, metrics, 0), Map.get(comparison, metrics, 0)]
      Enum.max(value) != 0 || Enum.min(value) != 0
    end)
    |> Enum.sort(fn project_stats1, project_stats2 ->
      first_max = Enum.max([abs(Map.get(project_stats1.values.current, metrics)), abs(Map.get(project_stats1.values.comparison, metrics))])
      second_max = Enum.max([abs(Map.get(project_stats2.values.current, metrics)), abs(Map.get(project_stats2.values.comparison, metrics))])
      first_max > second_max
    end)

    max_value = stats
                |> Enum.map(fn %{values: %{current: current, comparison: comparison}} ->
                  current_value = abs(Map.get(current, metrics))
                  comparison_value = abs(Map.get(comparison, metrics))
                  Enum.max([current_value, comparison_value])
                end)
    max_value = max_value ++ [Enum.max([abs(Map.get(current_total, metrics) || 0), abs(Map.get(comparison_total, metrics) || 0)])]
    |> Enum.max

    %{
      stats: stats,
      periods: %{current: {current_start, current_end}, comparison: {comparison_start, comparison_end}},
      totals: %{current: current_total, comparison: comparison_total},
      max_value: max_value
    }
  end

  def get_stats(:month = period, previous_period, project_ids, metrics) do
    get_stats(get_period(period, previous_period), project_ids, metrics)
  end

  def get_stats(:year, _, project_ids, metrics) do
    get_stats(get_period(:year), project_ids, metrics)
  end

  def get_stats(:days30 = period, _, project_ids, metrics) do
    get_stats(get_period(period), project_ids, metrics)
  end

  def get_stats(:months12 = period, _, project_ids, metrics) do
    get_stats(get_period(period), project_ids, metrics)
  end

  def get_charts({daily_from, daily_to, _, _}, {monthly_from, monthly_to, _, _}, project_ids) do
    days_diff = Timex.diff(daily_to, daily_from, :days)
    months_diff = Timex.diff(monthly_to, monthly_from, :months)
    initial_daily_data = Enum.into(0..days_diff, Keyword.new, fn n ->
      date = Timex.shift(daily_from, days: n)
      {to_atom(Gt.Date.format(date, :date)), %Gt.DashboardChart{date: date}}
    end)
    initial_monthly_data = Enum.into(0..months_diff, Keyword.new, fn n ->
      date = Timex.shift(monthly_from, months: n)
      {to_atom(Gt.Date.format(date, :date)), %Gt.DashboardChart{date: date}}
    end)

    daily_charts = Enum.reduce(project_ids, %{}, fn project_id, acc ->
      data = DailyStats
      |> DailyStats.dashboard_charts
      |> DailyStats.by_project(project_id)
      |> DailyStats.by_period(daily_from, daily_to)
      |> Repo.all
      |> Enum.reduce(initial_daily_data, fn %{date: date} = stat, acc ->
        Keyword.update!(acc, String.to_atom(Gt.Date.format(date, :date)), fn _ -> struct(Gt.DashboardChart, stat) end)
      end)
      |> Keyword.values
      Map.put(acc, project_id, data)
    end)

    monthly_charts = Enum.reduce(project_ids, %{}, fn project_id, acc ->
      data = MonthlyStats
      |> MonthlyStats.dashboard_charts
      |> MonthlyStats.by_project(project_id)
      |> MonthlyStats.by_period(monthly_from, monthly_to)
      |> Repo.all
      |> Enum.reduce(initial_monthly_data, fn %{date: date} = stat, acc ->
        Keyword.update!(acc, String.to_atom(Gt.Date.format(date, :date)), fn _ -> struct(Gt.DashboardChart, stat) end)
      end)
      |> Keyword.values
      Map.put(acc, project_id, data)
    end)

    total_daily_charts = DailyStats
                         |> DailyStats.dashboard_charts(:total)
                         |> DailyStats.by_projects(project_ids)
                         |> DailyStats.by_period(daily_from, daily_to)
                         |> Repo.all
                         |> Enum.reduce(initial_daily_data, fn %{date: date} = stat, acc ->
                           Keyword.update!(acc, String.to_atom(Gt.Date.format(date, :date)), fn _ -> struct(Gt.DashboardChart, stat) end)
                         end)
                         |> Keyword.values

    total_monthly_charts = MonthlyStats
                           |> MonthlyStats.dashboard_charts(:total)
                           |> MonthlyStats.by_projects(project_ids)
                           |> MonthlyStats.by_period(monthly_from, monthly_to)
                           |> Repo.all
                           |> Enum.reduce(initial_monthly_data, fn %{date: date} = stat, acc ->
                             Keyword.update!(acc, String.to_atom(Gt.Date.format(date, :date)), fn _ -> struct(Gt.DashboardChart, stat) end)
                           end)
                           |> Keyword.values

    stats = Enum.into(project_ids, %{}, fn id ->
      {id, %{daily: daily_charts[id], monthly: monthly_charts[id]}}
    end)

    %{
      stats: stats,
      totals: %{
        daily: total_daily_charts,
        monthly: total_monthly_charts
      }
    }
  end

  def get_charts(:month, project_ids) do
    get_charts(get_period(:month), get_period(:months12), project_ids)
  end

  def get_charts(:year, project_ids) do
    get_charts(get_period(:year), get_period(:months12), project_ids)
  end

  def get_charts(:days30, project_ids) do
    get_charts(get_period(:days30), get_period(:months12), project_ids)
  end

  def get_charts(:months12, project_ids) do
    get_charts(get_period(:months12), get_period(:months12), project_ids)
  end

  def chart(:daily, user, metrics, id) do
    project_ids = Project.allowed(user, "dashboard_index")
    {from, to, _, _} = Map.get(user.settings, :dashboard_period, "month") |> to_atom |> get_period
    metrics = to_atom(metrics)

    days_diff = Timex.diff(to, from, :days)
    initial_data = Enum.into(0..days_diff, Keyword.new, fn n ->
      date = Timex.shift(from, days: n)
      result = %{date: date} |> Map.put(metrics, 0)
      {to_atom(Gt.Date.format(date, :date)), result}
    end)

    query = DailyStats
            |> DailyStats.by_period(from, to)
            |> DailyStats.daily_chart

    if id == "total" do
      query |> DailyStats.by_projects(project_ids)
    else
      query |> DailyStats.by_project(id)
    end
    |> Repo.all
    |> Enum.reduce(initial_data, fn %{date: date} = stat, acc ->
      Keyword.update!(acc, to_atom(Gt.Date.format(date, :date)), fn _ ->
        result = Map.get(stat, metrics, 0)
        result = if Decimal.decimal?(result), do: Decimal.to_float(result), else: result
        %{date: date} |> Map.put(metrics, result)
      end)
    end)
    |> Keyword.values
  end

  def chart(:monthly, user, metrics, id) do
    project_ids = Project.allowed(user, "dashboard_index")
    {from, to, _, _} = get_period(:months12)
    metrics = to_atom(metrics)

    months_diff = Timex.diff(to, from, :months)
    initial_data = Enum.into(0..months_diff, Keyword.new, fn n ->
      date = Timex.shift(from, months: n)
      result = %{date: date} |> Map.put(metrics, 0)
      {to_atom(Gt.Date.format(date, :date)), result}
    end)

    query = MonthlyStats
            |> MonthlyStats.by_period(from, to)
            |> MonthlyStats.monthly_chart

    if id == "total" do
      query |> MonthlyStats.by_projects(project_ids)
    else
      query |> MonthlyStats.by_project(id)
    end
    |> Repo.all
    |> Enum.reduce(initial_data, fn %{date: date} = stat, acc ->
      Keyword.update!(acc, to_atom(Gt.Date.format(date, :date)), fn _ ->
        result = Map.get(stat, metrics, 0)
        result = if Decimal.decimal?(result), do: Decimal.to_float(result), else: result
        %{date: date} |> Map.put(metrics, result)
      end)
    end)
    |> Keyword.values
  end

  defp set_depositors(stats, data) when is_list(data) do
    Enum.reduce(data, stats, fn
      %{depositors: depositors, transactors: transactors, project_id: project_id}, acc ->
        Map.put(acc, project_id, %{acc[project_id] | depositors: depositors || 0, transactors: transactors || 0})
    end)
  end

  defp set_depositors(stats, %{depositors: depositors, transactors: transactors}) do
    %{stats | depositors: depositors || 0, transactors: transactors || 0}
  end

  defp set_stats(stats, data) when is_list(data) do
    Enum.reduce(data, stats, fn %{project_id: project_id} = project_stats, acc ->
      avg_arpu = if acc[project_id].transactors == 0, do: 0, else: project_stats.inout_sum / acc[project_id].transactors
      Map.put(acc, project_id, %{acc[project_id] |
        inout_sum: project_stats.inout_sum || 0,
        inout_num: project_stats.inout_num || 0,
        deps_sum: project_stats.deps_sum || 0,
        deps_num: project_stats.deps_num || 0,
        wdrs_sum: project_stats.wdrs_sum || 0,
        wdrs_num: project_stats.wdrs_num || 0,
        first_deps_sum: project_stats.first_deps_sum || 0,
        first_depositors: project_stats.first_depositors || 0,
        signups: project_stats.signups || 0,
        avg_dep: Decimal.to_float(project_stats.avg_dep) || 0,
        avg_arpu: avg_arpu || 0,
        avg_first_dep: project_stats.avg_first_dep || 0,
        netgaming_sum: project_stats.netgaming_sum || 0,
        bets_sum: project_stats.bets_sum || 0,
        bets_num: project_stats.bets_num || 0,
        wins_sum: project_stats.wins_sum || 0,
        wins_num: project_stats.wins_num || 0,
        rake_sum: project_stats.rake_sum || 0,
        authorizations: project_stats.authorizations || 0,
      })
    end)
  end

  defp set_stats(stats, data) when is_map(data) do
    avg_arpu = if stats.transactors == 0 || !data.inout_sum, do: 0, else: data.inout_sum / stats.transactors
    avg_dep = if Decimal.decimal?(data.avg_dep), do: Decimal.to_float(data.avg_dep), else: 0
    %{stats |
      inout_sum: data.inout_sum || 0,
      inout_num: data.inout_num || 0,
      deps_sum: data.deps_sum || 0,
      deps_num: data.deps_num || 0,
      wdrs_sum: data.wdrs_sum || 0,
      wdrs_num: data.wdrs_num || 0,
      first_deps_sum: data.first_deps_sum || 0,
      first_depositors: data.first_depositors || 0,
      signups: data.signups || 0,
      avg_dep: avg_dep || 0,
      avg_arpu: avg_arpu || 0,
      avg_first_dep: data.avg_first_dep || 0,
      netgaming_sum: data.netgaming_sum || 0,
      bets_sum: data.bets_sum || 0,
      bets_num: data.bets_num || 0,
      wins_sum: data.wins_sum || 0,
      wins_num: data.wins_num || 0,
      rake_sum: data.rake_sum || 0,
      authorizations: data.authorizations || 0,
    }
  end

end
