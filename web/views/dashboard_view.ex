defmodule Gt.DashboardView do
  use Gt.Web, :view
  use Timex
  alias Gt.CalendarEvent
  alias Gt.Repo
  alias Gt.Auth.Permissions
  import Ecto.Query

  def render("chart_daily.json", %{stats: stats, metrics: metrics}) do
    stats |> chart_data(metrics)
  end

  def render("chart_monthly.json", %{stats: stats, metrics: metrics}) do
    stats |> chart_data(metrics)
  end

  def format_period(user, {from, _to}, current \\ true) do
    case user.settings.dashboard_period do
      "month" ->
        from |> Timex.format!("{M}") |> String.to_integer |> Gt.Date.month_to_name
      "year" ->
        from |> Timex.format!("{YYYY}")
      _ -> if current do
        dgettext "dashboard", "current"
      else
        dgettext "dashboard", "previous"
      end
    end
  end

  def format_date(date) do
    Gt.Date.translate(date, :date)
  end

  def progress_width(max_value, value) do
    case max_value do
      0 -> 0
      _ -> round(abs(value) / max_value * 100)
    end
  end

  def metrics_color(metrics) do
    case metrics do
      "inout_sum" -> "blue"
      "deps_sum" -> "green"
      "wdrs_sum" -> "deep-orange"
      "netgaming_sum" -> "pink"
      "bets_sum" -> "teal"
      "wins_sum" -> "orange"
      "first_deps_sum" -> "blue-grey"
      "rake_sum" -> "purple"
    end
  end

  def chart_data(data, metrics) when is_bitstring(metrics) do
    chart_data(data, String.to_atom(metrics))
  end

  def chart_data(data, metrics) when is_atom(metrics) do
    Enum.map(data, fn point ->
      cond do
        Enum.member?([:deps_num, :depositors, :first_depositors, :signups, :authorizations], metrics) ->
          %{y: Map.get(point, metrics), x: Timex.to_unix(point.date)}
        true ->
          value = Map.get(point, metrics)
          filtered_value = case metrics == :wdrs_sum do
            true -> abs value
            false -> value
          end
          %{y: round(filtered_value / 100), x: Timex.to_unix(point.date)}
      end
    end)
  end

  def chart_labels(data, :daily) do
    Enum.map(data, fn point ->
      Gt.Date.translate(point.date, :date)
    end)
  end

  def chart_labels(data, :monthly) do
    Enum.map(data, fn point ->
      Gt.Date.translate(point.date, :month)
    end)
  end

  def chart_timestamps(data) do
    Enum.map(data, &(Timex.to_unix(&1.date) * 1000))
  end

  def last_events("total", user) do
    query = CalendarEvent
            |> order_by(desc: :inserted_at)
            |> preload(:type)
            |> preload(:projects)
            |> limit(3)
    if user.is_admin do
      query
    else
      ids = Permissions.get(user.permissions, "events_list") |> Enum.map(&String.to_integer/1)
      CalendarEvent.by_projects(query, ids)
    end
    |> Repo.all
  end

  def last_events(id, _user) do
    CalendarEvent
    |> join(:left, [ce], cep in "calendar_event_projects", cep.calendar_event_id == ce.id)
    |> where([ce, cep], cep.project_id == ^id)
    |> order_by([ce], desc: ce.inserted_at)
    |> preload(:type)
    |> preload(:projects)
    |> limit(3)
    |> Repo.all
  end

  def format_event_date(date) do
    Gt.Date.format(date, :date)
  end

end
