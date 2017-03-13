defmodule Gt.CacheWorker do
  use GenServer
  alias Gt.Cache
  alias Gt.CacheRegistry
  alias Gt.Repo
  alias Gt.Payment
  alias Gt.ProjectUser
  alias Gt.ProjectUserGame
  alias Gt.PokerGame
  alias Gt.DailyStats
  alias Gt.MonthlyStats
  alias Gt.UserLogin
  alias Gt.ProjectUserStat
  import Ecto.Query, only: [where: 3, select: 3, preload: 2]
  require Logger
  use Timex

  def send_socket(cache) do
    processed = CacheRegistry.find(cache.id, :processed)
    total = CacheRegistry.find(cache.id, :total)
    Gt.Endpoint.broadcast("cache:#{cache.id}", "cache:update", %{cache | processed: processed, total: total})
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end

  @doc """
  Calculate consolidated stats.
  Should be run after stats cache
  """
  def handle_cast(:consolidated, state) do
    Logger.metadata(channel: :cache_consolidated, id: state.cache.id)
    Logger.info("Start worker")

    # Load cache from db since it may be called with delay
    cache = Repo.get!(Cache, state.cache.id) |> init_worker
    project_ids = cache.projects
    from = cache.start
    to = cache.end
    period = "[#{from |> Timex.format!("{ISOdate}")}|#{to |> Timex.format!("{ISOdate}")}]"
    Logger.metadata(period: period)

    {:ok, timer} = :timer.apply_interval(500, __MODULE__, :send_socket, [cache])

    Logger.info("Delete daily stats")
    DailyStats
    |> DailyStats.by_period(from, to)
    |> DailyStats.by_projects(project_ids)
    |> Repo.delete_all()

    Payment.dashboard_stats(from, to, project_ids)
    |> Repo.all
    |> process_payments(cache.id)

    ProjectUser.first_deposit_stats(from, to, project_ids)
    |> Repo.all
    |> process_first_deposit_stats(cache.id)

    ProjectUser.vip_levels()
    |> Enum.with_index()
    |> Enum.map(fn {vip_level, i} ->
      process_daily_vip_level(from, to, project_ids, cache.id, "vip_#{vip_level}", i)
    end)

    ProjectUser.signup_stats(from, to, project_ids)
    |> Repo.all
    |> process_signups(cache.id)

    ProjectUserGame.netgaming(from, to, project_ids)
    |> Repo.all
    |> process_netgaming(cache.id)

    PokerGame.rake(from, to, project_ids)
    |> Repo.all
    |> process_rake(cache.id)

    UserLogin.authorizations_by_period(from, to, project_ids)
    |> Repo.all
    |> process_authorizations(cache.id)

    consolidated_monthly(cache.id, from, to, project_ids)
    Logger.info("Complete worker")

    :timer.cancel(timer)
    if cache.interval do
      cache = complete_consolidated(cache, new_period(cache))
      Process.send_after(self(), {:"$gen_cast", :consolidated}, cache.interval * 60 * 1000)
      {:noreply, %{cache: cache}}
    else
      {:stop, :normal, %{state | cache: complete_consolidated(cache)}}
    end
  end

  @doc """
  Calculate vip levels stats.
  Must by run after stats cache
  """
  def handle_cast(:vip, state) do
    Logger.metadata(channel: :cache_vip, id: state.cache.id)
    Logger.info("Start worker")

    cache = init_worker(state.cache)
    project_ids = cache.projects
    project_users_query = ProjectUser
                          |> where([pu], pu.project_id in ^project_ids)
    total = project_users_query
            |> select([pu], count(pu.id))
            |> Repo.one
    Logger.info("Calculating cache for #{total} users")
    CacheRegistry.save(cache.id, :total, total)
    project_users = project_users_query
                    |> preload(:project)
                    |> Repo.all

    {:ok, timer} = :timer.apply_interval(500, __MODULE__, :send_socket, [cache])
    project_users
    |> ParallelStream.map(fn project_user ->
      ProjectUser.calculate_vip_levels(project_user)
      CacheRegistry.increment(cache.id, :processed)
    end) |> Enum.reduce(0, fn _, acc -> acc + 1 end)
    :timer.cancel(timer)
    processed = CacheRegistry.find(cache.id, :processed)
    Cache.changeset(cache, %{active: false, total: total, processed: processed, completed: true}) |> Repo.update!
    Logger.info("Compete worker")
    {:stop, :normal, state}
  end

  @doc """
  Calculate project users stats.
  """
  def handle_cast(:stats, state) do
    Logger.metadata(channel: :cache_stats, id: state.cache.id)
    Logger.info("Start worker")

    cache = init_worker(state.cache)
    project_ids = cache.projects
    project_users_query = ProjectUser |> where([pu], pu.project_id in ^project_ids)
    total = project_users_query
            |> select([pu], count(pu.id))
            |> Repo.one
    project_users = project_users_query
                    |> preload(:project)
                    |> Repo.all
    CacheRegistry.save(cache.id, :total, total)
    period = "[#{cache.start |> Timex.format!("{ISOdate}")}|#{cache.end |> Timex.format!("{ISOdate}")}]"
    Logger.metadata(period: period)
    Logger.info("Calculating cache for #{total} users")
    {:ok, timer} = :timer.apply_interval(500, __MODULE__, :send_socket, [cache])

    project_users
    |> ParallelStream.map(fn project_user ->
      ProjectUser.calculate_stats(project_user, cache.start, cache.end)
      ProjectUser.deps_wdrs_cache(project_user)
      CacheRegistry.increment(cache.id, :processed)
    end) |> Enum.reduce(0, fn _, acc -> acc + 1 end)
    :timer.cancel(timer)
    processed = CacheRegistry.find(cache.id, :processed)
    Cache.changeset(cache, %{active: false, total: total, processed: processed, completed: true}) |> Repo.update!
    Logger.info("Compete worker")
    {:stop, :normal, state}
  end

  def terminate(:normal, state) do
    %Gt.WorkerStatus{state: ":normal"} |> terminate(state)
  end

  def terminate(%Gt.WorkerStatus{} = status, state) do
    cache = state.cache
    cache
    |> Cache.changeset(%{active: false})
    |> Ecto.Changeset.put_embed(:status, status)
    |> Repo.update
    CacheRegistry.delete(cache.id)
    Gt.Endpoint.broadcast("cache:#{cache.id}", "cache:update", cache)
    cache
  end

  def terminate(reason, state) do
    CacheRegistry.delete(state.cache.id)
    %Gt.WorkerStatus{state: "danger", text: inspect(reason, pretty: true, width: 0) |> String.replace("\n", "<br>")}
    |> terminate(state)
  end

  defp init_worker(cache) do
    CacheRegistry.create(cache.id)
    CacheRegistry.save(cache.id, :pid, self())
    CacheRegistry.save(cache.id, :processed, 0)
    Cache.clear_state(cache)
  end

  defp process_payments(data, cache_id) do
    Logger.info "Aggregating payments"
    total = length data
    CacheRegistry.save(cache_id, :total, total * 11)
    CacheRegistry.save(cache_id, :processed, 0)
    Logger.info "Updating dashboard payments"

    ParallelStream.each(data, fn item ->
      date = Date.from_erl!(item.date)
      avg_dep = case Float.parse(to_string(item.avg_dep)) do
        {avg_dep, _} -> avg_dep
        _ -> 0.0
      end
      avg_arpu = case Float.parse(to_string(item.avg_arpu)) do
        {avg_arpu, _} -> avg_arpu
        _ -> 0.0
      end
      %DailyStats{}
      |> DailyStats.changeset(%{
        date: date,
        inout_sum: item.inout_sum,
        inout_num: item.inout_num,
        deps_sum: item.deps_sum,
        deps_num: item.deps_num,
        wdrs_sum: item.wdrs_sum,
        wdrs_num: item.wdrs_num,
        depositors: item.depositors,
        avg_dep: avg_dep,
        avg_arpu: avg_arpu,
        transactors: item.transactors,
        project_id: item.project_id,
      })
      |> Repo.insert!

      CacheRegistry.increment(cache_id, :processed)
    end) |> Enum.to_list()
    Logger.info "Completed updating dashboard payments"
  end

  defp process_first_deposit_stats(data, cache_id) do
    Logger.info "Aggregating first deposit stats"
    total = length data
    CacheRegistry.save(cache_id, :total, total * 11)
    CacheRegistry.save(cache_id, :processed, total)
    Logger.info "Updating first deposit stats"
    Enum.each(data, fn item ->
      avg_first_dep = case Float.parse(to_string(item.avg_first_dep)) do
        {avg_dep, _} -> avg_dep
        _ -> 0.0
      end
      daily_stats = DailyStats
      |> DailyStats.by_project(item.project_id)
      |> DailyStats.by_date(Timex.to_date(item.date))
      |> Repo.one
      if daily_stats do
        DailyStats.changeset(daily_stats, %{
          first_deps_sum: item.first_deps_sum,
          avg_first_dep: avg_first_dep,
          first_depositors: item.first_depositors,
          project_id: daily_stats.project_id
        })
        |> Repo.update!
      else
        %DailyStats{}
        |> DailyStats.changeset(%{
          date: Timex.to_date(item.date),
          first_deps_sum: item.first_deps_sum,
          avg_first_dep: avg_first_dep,
          first_depositors: item.first_depositors,
          project_id: item.project_id,
        })
        |> Repo.insert!
      end

      CacheRegistry.increment(cache_id, :processed)
    end)
    Logger.info "Completed updating first deposit stats"
  end

  defp process_signups(data, cache_id) do
    Logger.info "Aggregating signups"
    total = length data
    CacheRegistry.save(cache_id, :total, total * 11)
    CacheRegistry.save(cache_id, :processed, total * 6)
    Logger.info "Updating signups"
    Enum.each(data, fn item ->
      daily_stats = DailyStats
      |> DailyStats.by_project(item.project_id)
      |> DailyStats.by_date(item.date |> Timex.to_date)
      |> Repo.one
      if daily_stats do
        DailyStats.changeset(daily_stats, %{
          signups: item.signups,
        })
        |> Repo.update!
      else
        %DailyStats{}
        |> DailyStats.changeset(%{
          date: item.date,
          signups: item.signups,
          project_id: item.project_id,
        })
        |> Repo.insert!
      end

      CacheRegistry.increment(cache_id, :processed)
    end)
    Logger.info "Completed updating signups"
  end

  defp process_netgaming(data, cache_id) do
    Logger.info "Aggregating netgaming"
    total = length data
    CacheRegistry.save(cache_id, :total, total * 11)
    CacheRegistry.save(cache_id, :processed, total * 7)
    Logger.info "Updating netgaming"
    Enum.each(data, fn item ->
      date = Date.from_erl!(item.date)
      daily_stats = DailyStats
      |> DailyStats.by_project(item.project_id)
      |> DailyStats.by_date(date)
      |> Repo.one
      if daily_stats do
        DailyStats.changeset(daily_stats, %{
          bets_sum: item.bets_sum,
          bets_num: item.bets_num,
          wins_sum: item.wins_sum,
          wins_num: item.wins_num,
          netgaming_sum: item.netgaming_sum
        })
        |> Repo.update!
      else
        %DailyStats{}
        |> DailyStats.changeset(%{
          date: date,
          bets_sum: item.bets_sum,
          bets_num: item.bets_num,
          wins_sum: item.wins_sum,
          wins_num: item.wins_num,
          netgaming_sum: item.netgaming_sum,
          project_id: item.project_id
        })
        |> Repo.insert!
      end

      CacheRegistry.increment(cache_id, :processed)
    end)
    Logger.info "Completed updating netgaming"
  end

  defp process_rake(data, cache_id) do
    Logger.info "Aggregating rake"
    total = length data
    CacheRegistry.save(cache_id, :total, total * 11)
    CacheRegistry.save(cache_id, :processed, total * 8)
    Logger.info "Updating rake"
    Enum.each(data, fn item ->
      date = Date.from_erl!(item.date)
      daily_stats = DailyStats
      |> DailyStats.by_project(item.project_id)
      |> DailyStats.by_date(date)
      |> Repo.one
      if daily_stats do
        DailyStats.changeset(daily_stats, %{
          rake_sum: item.rake_sum
        })
        |> Repo.update!
      else
        %DailyStats{}
        |> DailyStats.changeset(%{
          date: date,
          rake_sum: item.rake_sum,
          project_id: item.project_id,
        })
        |> Repo.insert!
      end

      CacheRegistry.increment(cache_id, :processed)
    end)
    Logger.info "Completed updating rake"
  end

  defp process_authorizations(data, cache_id) do
    Logger.info "Aggregating authorizations"
    total = length data
    CacheRegistry.save(cache_id, :total, total * 11)
    CacheRegistry.save(cache_id, :processed, total * 9)
    Logger.info "Updating authorizations"
    Enum.each(data, fn item ->
      date = Date.from_erl!(item.date)
      daily_stats = DailyStats
      |> DailyStats.by_project(item.project_id)
      |> DailyStats.by_date(date)
      |> Repo.one
      if daily_stats do
        DailyStats.changeset(daily_stats, %{
          authorizations: item.authorizations
        })
        |> Repo.update!
      else
        %DailyStats{}
        |> DailyStats.changeset(%{
          date: date,
          authorizations: item.authorizations,
          project_id: item.project_id,
        })
        |> Repo.insert!
      end

      CacheRegistry.increment(cache_id, :processed)
    end)
    Logger.info "Completed updating authorizations"
  end

  defp complete_consolidated(cache, new_dates \\ nil) do
    {from, to} = case new_dates do
      nil -> {cache.start, cache.end}
      {from, to} -> {from, to}
    end
    cache = cache
    |> Cache.changeset(%{
      active: false,
      total: CacheRegistry.find(cache.id, :total) || 0,
      processed: CacheRegistry.find(cache.id, :processed) || 0,
      completed: true,
      start: from,
      end: to,
    })
    if new_dates do
      %Gt.WorkerStatus{state: ":normal"} |> terminate(%{cache: Repo.update!(cache)})
    else
      cache |> Repo.update!
    end
  end

  defp consolidated_monthly(cache_id, from, to, project_ids) do
    Logger.info "Aggregating monthly stats"
    from = Timex.set(from, day: 1)
    to = Timex.set(to, day: 1)
    diff = Timex.diff(from, to, :months) |> abs

    MonthlyStats
    |> MonthlyStats.by_period(from, to)
    |> MonthlyStats.by_projects(project_ids)
    |> Repo.delete_all()

    interval = Interval.new(from: from, until: [months: diff], step: [months: 1], right_open: false)
    total = Enum.count(interval)
    CacheRegistry.save(cache_id, :total, total * 11)
    CacheRegistry.save(cache_id, :processed, total * 10)
    interval
    |> ParallelStream.map(fn month ->
      from = Timex.to_date(month)
      to = from |> Timex.set(day: Timex.days_in_month(month))
      stats = DailyStats.monthly(from, to, project_ids) |> Repo.all

      if length(stats) > 0 do
        Enum.map(stats, fn item ->
          {:ok, date} = Timex.parse(item.date, "%Y-%m-%d", :strftime)
          date = Timex.to_date(date)
          avg_dep = case Float.parse(to_string(item.avg_dep)) do
            {avg_dep, _} -> avg_dep
            _ -> nil
          end
          avg_first_dep = case Float.parse(to_string(item.avg_first_dep)) do
            {avg_first_dep, _} -> avg_first_dep
            _ -> nil
          end

          %MonthlyStats{}
          |> MonthlyStats.changeset(%{
            date: date,
            inout_sum: item.inout_sum,
            inout_num: item.inout_num,
            deps_sum: item.deps_sum,
            deps_num: item.deps_num,
            wdrs_sum: item.wdrs_sum,
            wdrs_num: item.wdrs_num,
            first_depositors: item.first_depositors,
            first_deps_sum: item.first_deps_sum,
            signups: item.signups,
            avg_dep: avg_dep,
            avg_first_dep: avg_first_dep,
            netgaming_sum: item.netgaming_sum,
            bets_sum: item.bets_sum,
            wins_sum: item.wins_sum,
            bets_num: item.bets_num,
            wins_num: item.wins_num,
            rake_sum: item.rake_sum,
            authorizations: item.authorizations,
            project_id: item.project_id,
            vip_1000: item.vip_1000,
            vip_1500: item.vip_1500,
            vip_2500: item.vip_2500,
            vip_5000: item.vip_5000,
          })
          |> Repo.insert!
        end)
        ProjectUserStat.depositors_monthly(from, to, project_ids)
        |> Repo.all
        |> Enum.map(fn item ->
          {:ok, date} = Timex.parse(item.date, "%Y-%m-%d", :strftime)
          date = Timex.to_date(date)
          monthly_stats = MonthlyStats
          |> MonthlyStats.by_project(item.project_id)
          |> MonthlyStats.by_date(date)
          |> Repo.one!

          avg_arpu = if item.depositors == 0, do: 0, else: monthly_stats.deps_sum / item.depositors
          monthly_stats
          |> MonthlyStats.changeset(%{
            transactors: item.transactors,
            depositors: item.depositors,
            avg_arpu: avg_arpu,
          })
          |> Repo.update!
        end)
      end
      CacheRegistry.increment(cache_id, :processed)
    end)
    |> Enum.to_list
  end

  defp process_daily_vip_level(from, to, project_ids, cache_id, vip_level, i) do
    Logger.info "Aggregating daily vip level #{vip_level}"

    data = ProjectUser.vip_level_by_date(from, to, project_ids, String.to_atom(vip_level))
    |> Repo.all

    total = length data
    CacheRegistry.save(cache_id, :total, total * 11)
    CacheRegistry.save(cache_id, :processed, total * (2 + i))
    Logger.info "Updating daily vip level"
    Enum.each(data, fn item ->
      daily_stats = DailyStats
      |> DailyStats.by_project(item.project_id)
      |> DailyStats.by_date(item.date)
      |> Repo.one
      params = %{project_id: item.project_id} |> Map.put(String.to_atom(vip_level), item.num)
      if daily_stats do
        DailyStats.changeset(daily_stats, params) |> Repo.update!
      else
        %DailyStats{}
        |> DailyStats.changeset(Map.put(params, :date, item.date))
        |> Repo.insert!
      end
      CacheRegistry.increment(cache_id, :processed)
    end)
    Logger.info "Completed updating daily vip level #{vip_level}"
  end

  defp new_period(cache) do
    from = cache.start
    to = cache.end
    today = Timex.today
    yesterday = today |> Timex.shift(days: -1)
    new_from = Timex.shift(to, days: 1)
    new_from = if Timex.compare(new_from, yesterday) >= 0, do: yesterday, else: new_from
    new_to = Timex.shift(new_from, days: Timex.diff(to, from, :days))
    new_to = if Timex.compare(new_to, today) >= 0, do: today, else: new_to
    {new_from, new_to}
  end

end
