defmodule Gt.DashboardController do
  use Gt.Web, :controller
  use Timex
  alias Gt.User
  alias Gt.UserSettings
  alias Gt.Report.Dashboard

  plug EnsureAuthenticated, [handler: Gt.SessionController]

  def index(conn, %{"user_settings" => user_settings} = params, user) do
    user = Repo.preload(user, :settings)
    period = user_settings["dashboard_period"]
    user_settings = case Integer.parse(period) do
      {period, _} ->
        user_settings
        |> Map.put("dashboard_period", "month")
        |> Map.put("dashboard_compare_period", period)
      _ -> user_settings
    end
    user = User.changeset(user)
    |> Ecto.Changeset.put_assoc(:settings, UserSettings.changeset(user.settings, user_settings))
    |> Repo.update!
    index(conn, Map.delete(params, "user_settings"), user)
  end

  def index(conn, _params, user) do
    user = Repo.preload(user, :settings)
    user_settings = if user.settings.dashboard_period == "month" do
      Map.put(user.settings, :dashboard_period, user.settings.dashboard_compare_period)
    else
      user.settings
    end
    |> UserSettings.changeset
    today = Timex.today
    compare_periods = UserSettings.dashboard_compare_periods()
                      |> Enum.map(fn i ->
                        date = today |> Timex.shift(months: i)
                        label = date
                        |> Timex.format!("{M}")
                        |> String.to_integer
                        |> Gt.Date.month_to_name
                        {"#{label} #{Timex.format!(date, "{YYYY}")}", i}
                      end)

    render conn, "index.html",
      current_user: user,
      user_settings: user_settings,
      breadcrumbs: [],
      sort_metrics: [
        {dgettext("dashboard", "sort_by_inout_sum"), "inout_sum"},
        {dgettext("dashboard", "sort_by_deps_sum"), "deps_sum"},
        {dgettext("dashboard", "sort_by_wdrs_sum"), "wdrs_sum"},
        {dgettext("dashboard", "sort_by_netgaming_sum"), "netgaming_sum"},
        {dgettext("dashboard", "sort_by_bets_sum"), "bets_sum"},
        {dgettext("dashboard", "sort_by_wins_sum"), "wins_sum"},
        {dgettext("dashboard", "sort_by_first_deps_sum"), "first_deps_sum"},
      ],
      periods: [
        {dgettext("dashboard", "month"), compare_periods},
        {dgettext("dashboard", "year"), "year"},
        {dgettext("dashboard", "30_days"), "days30"},
        {dgettext("dashboard", "12_months"), "months12"},
      ],
      data: Dashboard.load_data(user)
  end

  def chart_daily(conn, %{"metrics" => metrics, "id" => id}, user) do
    user = Repo.preload(user, :settings)
    render conn, "chart_daily.json",
      stats: Dashboard.chart(:daily, user, metrics, id),
      metrics: metrics
  end

  def chart_monthly(conn, %{"metrics" => metrics, "id" => id}, user) do
    user = Repo.preload(user, :settings)
    render conn, "chart_monthly.json",
      stats: Dashboard.chart(:monthly, user, metrics, id),
      metrics: metrics
  end

  def add_breadcrumb(conn, active \\ true) do
    breadcrumb = [name: dgettext("menu", "dashboard")]
    if active do
      Keyword.put(breadcrumb, :url, dashboard_path(conn, :index))
    else
      breadcrumb
    end
  end

end
