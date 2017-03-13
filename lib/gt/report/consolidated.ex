defmodule Gt.Report.ConsolidatedModel do
  use Gt.Web, :model

  schema "abstract(consolidated_report)" do
    field :from, Gt.Type.Month
    field :to, Gt.Type.Month
    field :vip_level, :string

    belongs_to :project, Gt.Project
  end

  @required_fields ~w(from to vip_level project_id)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end

defmodule Gt.Report.Consolidated do
  use Timex
  alias Gt.Repo
  alias Gt.MonthlyStats
  import Gt.Gettext

  def create(allowed_projects, %Gt.Report.ConsolidatedModel{} = model) do
    case model.project_id in allowed_projects do
      true -> {:ok, get_report(model)}
      false -> [{:error, :project, nil, "access denied"}]
    end
  end

  defp get_report(%Gt.Report.ConsolidatedModel{project_id: project_id, from: from, to: to, vip_level: vip_level}) do
    stats = MonthlyStats
    |> MonthlyStats.by_period(from, to)
    |> MonthlyStats.by_project(project_id)
    |> Repo.all()
    months = Interval.new(from: from, until: to, step: [months: 1], right_open: false)
    report = ~w(
      avg_dep
      avg_arpu
      deps_num
      avg_first_dep
      signups
      deps_sum
      wdrs_sum
      wdrs_num
      inout_sum
      depositors
      first_depositors
      first_deps_sum
      first_depositors_to_signups
      authorizations
      vip_level
    )a
    |> Enum.into(%{},
      fn metrics ->
        stat = months
        |> Enum.map(fn month ->
          month = NaiveDateTime.to_date(month)
          value = case metrics do
            :first_depositors_to_signups ->
              first_depositors = get_value(stats, :first_depositors, month)
              signups = get_value(stats, :signups, month)
              if signups > 0, do: first_depositors / signups, else: 0
            :vip_level ->
              get_value(stats, String.to_atom("vip_#{vip_level}"), month)
            _ ->
              get_value(stats, metrics, month)
          end
          %{month: month, value: value, toPrevious: :eq}
        end)
        {metrics, stat}
      end
    )

    report = report
    |> Enum.into(%{}, fn {metrics, stat} ->
      stat = stat
      |> Enum.with_index
      |> Enum.map(&compare_values(stat, &1))
      {metrics, stat}
    end)
    %{stats: report, months: months}
  end

  defp get_value(stats, metrics, month) do
    stats
    |> Enum.find(%{}, fn stats ->
      stats.date == month
    end)
    |> Map.get(metrics, 0)
  end

  defp compare_values(stat, {monthly_stat, index}) do
    cond do
      index == 0 -> monthly_stat
      monthly_stat.value > Enum.at(stat, index - 1).value -> %{monthly_stat | toPrevious: :gt}
      monthly_stat.value < Enum.at(stat, index - 1).value -> %{monthly_stat | toPrevious: :lt}
      true -> monthly_stat
    end
  end
end
