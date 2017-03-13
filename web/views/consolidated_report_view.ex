defmodule Gt.ConsolidatedReportView do
  use Gt.Web, :view
  alias Elixlsx.Sheet
  alias Elixlsx.Workbook

  def render("report.xlsx", %{report: report}) do
    cash_values = ~w(avg_dep avg_arpu avg_first_dep deps_sum wdrs_sum inout_sum first_deps_sum)a
                  |> Enum.map(fn metrics ->
                    values = Enum.map(report.stats[metrics], fn stat ->
                      value = Money.new(round(stat.value)) |> Money.to_string(fractional_unit: true)
                      excel_cell_color(value, stat.toPrevious)
                    end)
                    {metrics, values}
                  end)
                  |> Enum.into(%{})
    numeric_values = ~w(deps_num signups deps_num wdrs_num depositors first_depositors authorizations vip_level)a
                     |> Enum.map(fn metrics ->
                       values = Enum.map(report.stats[metrics], fn stat ->
                         excel_cell_color(stat.value, stat.toPrevious)
                       end)
                       {metrics, values}
                     end)
                     |> Enum.into(%{})
    first_depositors_to_signups = report.stats.first_depositors_to_signups
                                  |> Enum.map(fn stat ->
                                    excel_cell_color("#{Float.round(stat.value * 100 / 1, 2)}%", stat.toPrevious)
                                  end)

    months = Enum.map(report.months, &Gt.Date.translate(&1, :month))
    merge_cells_col = Enum.count(months) + 1
    rows = [
      [[""]] ++ months,
      [[(dgettext "consolidated_report", "base_indicators"), bg_color: "#90a4ae", color: "#ffffff"]],
      [[(dgettext "consolidated_report", "avg_dep")]] ++ cash_values.avg_dep,
      [[(dgettext "consolidated_report", "avg_arpu")]] ++ cash_values.avg_arpu,
      [[(dgettext "consolidated_report", "deps_num")]] ++ numeric_values.deps_num,
      [[(dgettext "consolidated_report", "avg_first_dep")]] ++ cash_values.avg_first_dep,
      [[(dgettext "consolidated_report", "conversion_indicators"), bg_color: "#90a4ae", color: "#ffffff"]],
      [[(dgettext "consolidated_report", "signups")]] ++ numeric_values.signups,
      [[(dgettext "consolidated_report", "first_depositors_to_signups")]] ++ first_depositors_to_signups,
      [[(dgettext "consolidated_report", "profitability_indications"), bg_color: "#90a4ae", color: "#ffffff"]],
      [[(dgettext "consolidated_report", "deps_sum")]] ++ cash_values.deps_sum,
      [[(dgettext "consolidated_report", "deps_num")]] ++ numeric_values.deps_num,
      [[(dgettext "consolidated_report", "wdrs_sum")]] ++ cash_values.wdrs_sum,
      [[(dgettext "consolidated_report", "wdrs_num")]] ++ numeric_values.wdrs_num,
      [[(dgettext "consolidated_report", "inout_sum")]] ++ cash_values.inout_sum,
      [[(dgettext "consolidated_report", "depositors")]] ++ numeric_values.depositors,
      [[(dgettext "consolidated_report", "first_depositors")]] ++ numeric_values.first_depositors,
      [[(dgettext "consolidated_report", "first_deps_sum")]] ++ cash_values.first_deps_sum,
      [[(dgettext "consolidated_report", "avg_first_dep")]] ++ cash_values.avg_first_dep,
      [[(dgettext "consolidated_report", "avg_dep")]] ++ cash_values.avg_dep,
      [[(dgettext "consolidated_report", "avg_arpu")]] ++ cash_values.avg_arpu,
      [[(dgettext "consolidated_report", "players"), bg_color: "#90a4ae", color: "#ffffff"]],
      [[(dgettext "consolidated_report", "unique_users")]] ++ numeric_values.authorizations,
      [[(dgettext "consolidated_report", "vip_users")]] ++ numeric_values.vip_level,
    ]

    sheet = %Sheet{
      rows: rows,
      merge_cells: [
        {"A2", Elixlsx.Util.to_excel_coords(2, merge_cells_col)},
        {"A7", Elixlsx.Util.to_excel_coords(7, merge_cells_col)},
        {"A10", Elixlsx.Util.to_excel_coords(10, merge_cells_col)},
        {"A22", Elixlsx.Util.to_excel_coords(22, merge_cells_col)},
      ]
    }
    workbook = %Workbook{sheets: [sheet]}
    Elixlsx.write_to_memory(workbook, "report.xlsx")
    |> elem(1)
    |> elem(1)
  end

  def cell_class(stat) do
    case stat.toPrevious do
      :eq -> ""
      :gt -> "green lighten-3"
      :lt -> "red lighten-3"
    end
  end

  defp excel_cell_color(value, to_previous) do
    case to_previous do
      :eq -> [value, align_horizontal: :left]
      :gt -> [value, bg_color: "#A5D6A7", align_horizontal: :left]
      :lt -> [value, bg_color: "#EF9A9A", align_horizontal: :left]
    end
  end
end
