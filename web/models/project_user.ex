defmodule Gt.ProjectUser do
  use Gt.Web, :model
  alias Gt.Payment
  alias Gt.ProjectUserStat
  use Timex

  @deposit_track_time 172800 # 48 hours

  @vip_level_1000 1000
  @vip_level_1500 1500
  @vip_level_2500 2500
  @vip_level_5000 5000

  @type_buying "buying"
  @type_webmasters "webmasters"
  @type_internal "internal"
  @type_noref "noref"

  def traffic_sources(), do: [@type_buying, @type_webmasters, @type_internal, @type_noref]

  def traffic_source(:buying), do: @type_buying
  def traffic_source(:webmasters), do: @type_webmasters
  def traffic_source(:internal), do: @type_internal
  def traffic_source(:noref), do: @type_noref

  schema "project_users" do
    # todo: need to check these fields at prod
    field :item_id, :string
    field :email, :string
    field :email_hash, :string
    field :email_encrypted, :string
    field :email_valid, :integer
    field :email_not_found, :boolean
    field :email_confirmed, :boolean
    field :login, :string
    field :nick, :string
    field :phone, :string
    field :phone_valid, :integer
    field :first_name, :string
    field :last_name, :string
    field :lang, :string
    field :sex, :integer
    field :cash_real, :integer
    field :cash_user_real, :integer
    field :cash_fun, :integer
    field :cash_bonus, :integer
    field :currency, :string
    field :birthday, :string
    field :is_active, :boolean
    field :has_bonus, :boolean
    field :query1, :string
    field :reg_ip, :string
    field :reg_d, :naive_datetime, default: Timex.now |> Timex.to_naive_datetime
    field :reg_ref1, :string
    field :last_d, :naive_datetime
    field :status, :string
    field :segment, :integer
    field :segment_upd_t, :integer
    field :first_dep_d, :naive_datetime
    field :first_dep_sum, :integer
    field :second_dep_d, :naive_datetime
    field :second_dep_sum, :integer
    field :third_dep_d, :naive_datetime
    field :third_dep_sum, :integer
    field :first_wdr_d, :naive_datetime
    field :first_wdr_sum, :integer
    field :email_unsub_types, :map
    field :sms_unsub_types, :map
    field :last_dep_d, :naive_datetime
    field :remind_code, :string
    field :glow_id, :string
    field :donor, :string
    field :social_network, :string
    field :social_network_url, :string
    field :traffic_source, :string

    # vip levels
    field :vip_1000, :date
    field :vip_1500, :date
    field :vip_2500, :date
    field :vip_5000, :date

    # total stats
    field :deps, :integer, default: 0
    field :wdrs, :integer, default: 0
    field :deps_sum, :integer, default: 0
    field :wdrs_sum, :integer, default: 0

    belongs_to :project, Gt.Project

    has_many :phones, Gt.Phone

    has_many :ref_codes, Gt.RefCode

    has_many :daily_stats, {"user_daily_stats", Gt.ProjectUserStat}, foreign_key: :user_id

    has_many :monthly_stats, {"user_monthly_stats", Gt.ProjectUserStat}, foreign_key: :user_id

    has_one :action, Gt.ProjectUserAction
  end

  @required_fields ~w(item_id project_id)a

  @optional_fields ~w(
                      email_hash
                      email_encrypted
                      email_not_found
                      email_confirmed
                      email_valid
                      lang
                      currency
                      is_active
                      has_bonus
                      query1
                      reg_ref1
                      reg_d
                      last_d
                      status
                      segment
                      segment_upd_t
                      first_dep_d
                      first_dep_sum
                      second_dep_d
                      second_dep_sum
                      third_dep_d
                      third_dep_sum
                      first_wdr_d
                      first_wdr_sum
                      last_dep_d
                      email_unsub_types
                      sms_unsub_types
                      cash_real
                      cash_user_real
                      vip_1000
                      vip_1500
                      vip_2500
                      vip_5000
                      deps
                      wdrs
                      deps_sum
                      wdrs_sum
                      traffic_source
                    )a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:traffic_source, traffic_sources())
  end

  def vip_level(:"1000"), do: @vip_level_1000
  def vip_level(:"1500"), do: @vip_level_1500
  def vip_level(:"2500"), do: @vip_level_2500
  def vip_level(:"5000"), do: @vip_level_5000

  def vip_levels(), do: [@vip_level_1000, @vip_level_1500, @vip_level_2500, @vip_level_5000]

  def start_tracking(%__MODULE__{id: id}, ref_code) do
    ref_code = String.slice(ref_code, 0..31)
    Redix.command(:redix, ~w(SETEX ref_#{id} #{@deposit_track_time} #{ref_code}))
  end

  def parse_ref_codes(data, without_tracker \\ true) do
    Regex.scan(~r/p(\d+)p(\d+)p([\w\d]{4})(?:t(\d+))?(?:f(\d+))?(?:$|\W)/is, data)
    |> Enum.map(fn match ->
      code = Regex.replace(~r/(;|&|\?|#|=)/, match, "")
        if without_tracker do
          String.split(code, "t") |> hd()
        else
          code
        end
    end)
  end

  def by_project_item_id(query, project_id, item_id) do
    query
    |> where([pu], pu.project_id == ^project_id and pu.item_id == ^item_id)
  end

  def get_stat_by_date(stats, date) do
    stats
    |> Enum.with_index
    |> Enum.drop_while(fn {%{date: stat_date}, _} -> Timex.to_date(stat_date) != Timex.to_date(date) end)
    |> List.first
  end

  def first_deposit_stats(from, to, project_ids) do
    from(pu in __MODULE__,
         select: %{
           project_id: pu.project_id,
           date: fragment("date(?)", pu.first_dep_d),
           first_deps_sum: sum(pu.first_dep_sum),
           avg_first_dep: avg(pu.first_dep_sum),
           first_depositors: sum(1)
         },
         where: fragment("date(?) between ? and ? ", pu.first_dep_d, ^from, ^to) and pu.project_id in ^project_ids,
         group_by: [pu.project_id, fragment("date(?)", pu.first_dep_d)])
  end

  def signup_stats(from, to, project_ids) do
    from(pu in __MODULE__,
         select: %{
           project_id: pu.project_id,
           date: pu.reg_d,
           signups: sum(1)
         },
         where: fragment("date(?) between ? and ? ", pu.reg_d, ^from, ^to) and pu.project_id in ^project_ids,
         group_by: [pu.project_id, pu.reg_d])
  end

  def get_or_create(project_id, item_id, reg_d, currency \\ nil) do
    project_user = __MODULE__
                   |> by_project_item_id(project_id, item_id)
                   |> Repo.one

    if !project_user do
      project_user = %__MODULE__{}
      |> changeset(%{
        project_id: project_id,
        item_id: item_id,
        reg_d: reg_d,
        currency: currency,
      })
      |> Repo.insert!(on_conflict: :nothing)
      if !project_user.id, do: get_or_create(project_id, item_id, reg_d, currency), else: project_user
    else
      project_user
    end
    |> Repo.preload(:project)
  end

  def calculate_stats(project_user, from, to) do
    user_payments = Payment
                    |> Payment.approved()
                    |> Payment.by_user(project_user.id)
                    |> Payment.by_period(from, to)
                    |> select([p], {p.date, p.sum, p.type})
                    |> Repo.all

    daily_stats = Enum.reduce(user_payments, [], fn({date, sum, type}, acc) ->
      stat = get_stat_by_date(acc, date)
      {deps, deps_sum} = if Payment.type(:deposit) == type, do: {1, sum}, else: {0, 0}
      {wdrs, wdrs_sum} = if Payment.type(:withdrawal) == type, do: {1, abs(sum)}, else: {0, 0}
      case stat do
        nil ->
          [%{
            date: Timex.to_date(date),
            deps: deps,
            wdrs: wdrs,
            deps_sum: deps_sum,
            wdrs_sum: wdrs_sum,
            project_user_id: project_user.id,
            project_id: project_user.project_id
          } | acc]
        {stat, i} ->
          List.replace_at(acc, i, %{stat |
            deps: deps + stat.deps,
            wdrs: wdrs + stat.wdrs,
            deps_sum: deps_sum + stat.deps_sum,
            wdrs_sum: wdrs_sum + stat.wdrs_sum
          })
      end
    end)

    old_daily_stats = ProjectUserStat.daily()
                      |> ProjectUserStat.by_user(project_user.id)
                      |> ProjectUserStat.by_period(from, to)
                      |> select([udl], map(udl, [:date, :deps, :wdrs, :deps_sum, :wdrs_sum]))
                      |> Repo.all

    daily_stats = Enum.reduce(daily_stats, old_daily_stats, fn stat, acc ->
      case get_stat_by_date(acc, stat.date) do
        nil -> [stat | acc]
        {_, i} -> List.replace_at(acc, i, stat)
      end
    end)

    monthly_stats = daily_stats
                    |> Enum.map(fn %{date: date} = stat ->
                      %{stat | date: Timex.set(date, day: 1)}
                    end)
                    |> Enum.reduce([], fn %{date: date, deps: deps, wdrs: wdrs, deps_sum: deps_sum, wdrs_sum: wdrs_sum}, acc ->
                      stat = get_stat_by_date(acc, date)
                      case stat do
                        nil ->
                          [%{
                            date: date,
                            deps: deps,
                            wdrs: wdrs,
                            deps_sum: deps_sum,
                            wdrs_sum: wdrs_sum,
                            project_user_id: project_user.id,
                            project_id: project_user.project_id
                          } | acc]
                        {stat, i} ->
                          List.replace_at(acc, i, %{stat |
                            deps: deps + stat.deps,
                            wdrs: wdrs + stat.wdrs,
                            deps_sum: deps_sum + stat.deps_sum,
                            wdrs_sum: wdrs_sum + stat.wdrs_sum
                          })
                      end
                    end)

    ProjectUserStat.daily()
    |> ProjectUserStat.by_user(project_user.id)
    |> ProjectUserStat.by_period(from, to)
    |> Repo.delete_all()
    Repo.insert_all({"user_daily_stats", ProjectUserStat}, daily_stats)

    ProjectUserStat.monthly()
    |> ProjectUserStat.by_user(project_user.id)
    |> ProjectUserStat.by_period(Timex.set(from, day: 1), Timex.set(to, day: 1))
    |> Repo.delete_all()
    Repo.insert_all({"user_monthly_stats", ProjectUserStat}, monthly_stats)

    total_stats = ProjectUserStat.total_stats(project_user.id)
    project_user
    |> changeset(total_stats || %{})
    |> Repo.update!
  end

  def deps_wdrs_cache(project_user) do
    last_dep = Payment
               |> Payment.by_user(project_user.id)
               |> Payment.deposits()
               |> order_by(desc: :date)
               |> first()
               |> Repo.one

    deps = Payment
           |> Payment.by_user(project_user.id)
           |> Payment.deposits()
           |> order_by(asc: :date)
           |> limit(3)
           |> Repo.all

    first_wdr = Payment
                |> Payment.by_user(project_user.id)
                |> Payment.withdrawals()
                |> first(:date)
                |> Repo.one
    [first_wdr_sum, first_wdr_date] = if first_wdr, do: [abs(first_wdr.sum), first_wdr.date], else: [nil, nil]
    last_dep_date = if last_dep, do: last_dep.date, else: nil
    [first_dep, second_dep, third_dep] = Enum.map(0..2, fn i ->
      case Enum.fetch(deps, i) do
        {:ok, dep} -> %{sum: dep.sum, date: dep.date}
        _ -> %{sum: nil, date: nil}
      end
    end)
    project_user
    |> changeset(%{
      last_dep_d: last_dep_date,
      first_dep_d: first_dep.date,
      first_dep_sum: first_dep.sum,
      second_dep_d: second_dep.date,
      second_dep_sum: second_dep.sum,
      third_dep_d: third_dep.date,
      third_dep_sum: third_dep.sum,
      first_wdr_d: first_wdr_date,
      first_wdr_sum: first_wdr_sum,
    })
    |> Repo.update!
  end

  def calculate_vip_levels(project_user) do
    if project_user.deps_sum > @vip_level_1000 * 100 do
      vip_levels = ProjectUserStat.deps_cumulative(project_user.id)
                   |> Repo.all
                   |> Enum.reduce_while(
                     %{vip_1000: nil, vip_1500: nil, vip_2500: nil, vip_5000: nil},
                     fn %{"date" => date, "deps_sum" => sum}, acc ->
                     acc = if sum > @vip_level_1000 * 100 && !acc.vip_1000, do: %{acc | vip_1000: date}, else: acc
                     acc = if sum > @vip_level_1500 * 100 && !acc.vip_1500, do: %{acc | vip_1500: date}, else: acc
                     acc = if sum > @vip_level_2500 * 100 && !acc.vip_2500, do: %{acc | vip_2500: date}, else: acc
                     if sum > @vip_level_5000 * 100 && !acc.vip_5000, do: {:halt, %{acc | vip_5000: date}}, else: {:cont, acc}
                   end)
      project_user
      |> changeset(vip_levels)
      |> Repo.update!
    else
      project_user
      |> changeset(%{vip_1000: nil, vip_1500: nil, vip_2500: nil, vip_5000: nil})
      |> Repo.update!
    end
  end

  def vip_level_by_date(from, to, project_ids, vip_level) do
    __MODULE__
    |> vip_level_select_by_date(vip_level)
    |> where([pu], pu.project_id in ^project_ids)
    |> vip_level_where_by_date(from, to, vip_level)
    |> vip_level_group_by(vip_level)
  end

  defp vip_level_select_by_date(query, :vip_1000) do
    query
    |> select([pu], %{
      project_id: pu.project_id,
      date: pu.vip_1000,
      num: count(pu.vip_1000)
    })
  end

  defp vip_level_select_by_date(query, :vip_1500) do
    query
    |> select([pu], %{
      project_id: pu.project_id,
      date: pu.vip_1500,
      num: count(pu.vip_1500)
    })
  end

  defp vip_level_select_by_date(query, :vip_2500) do
    query
    |> select([pu], %{
      project_id: pu.project_id,
      date: pu.vip_2500,
      num: count(pu.vip_2500)
    })
  end

  defp vip_level_select_by_date(query, :vip_5000) do
    query
    |> select([pu], %{
      project_id: pu.project_id,
      date: pu.vip_5000,
      num: count(pu.vip_5000)
    })
  end

  defp vip_level_where_by_date(query, from, to, :vip_1000) do
    query |> where([pu], fragment("? between ? and ?", pu.vip_1000, ^from, ^to))
  end

  defp vip_level_where_by_date(query, from, to, :vip_1500) do
    query |> where([pu], fragment("? between ? and ?", pu.vip_1500, ^from, ^to))
  end

  defp vip_level_where_by_date(query, from, to, :vip_2500) do
    query |> where([pu], fragment("? between ? and ?", pu.vip_2500, ^from, ^to))
  end

  defp vip_level_where_by_date(query, from, to, :vip_5000) do
    query |> where([pu], fragment("? between ? and ?", pu.vip_5000, ^from, ^to))
  end

  defp vip_level_group_by(query, vip_level) do
    query |> group_by([pu], [^vip_level, :project_id])
  end

end
