defmodule Gt.ConsolidatedReportController do
  use Gt.Web, :controller

  alias Gt.Project
  alias Gt.Report.ConsolidatedModel
  alias Gt.Report.Consolidated
  require Logger

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :consolidated_report]

  def index(conn, params, user) do

    if Map.has_key?(params, "consolidated_model") do
      consolidated_params = params["consolidated_model"]

      changeset = %ConsolidatedModel{}
                  |> ConsolidatedModel.changeset(consolidated_params)
                  |> Map.put(:action, :insert)

      if changeset.valid? do
        allowed_projects = Project.options(Project, Project.allowed(user, "consolidated_report"))
                           |> Map.values()
        case Consolidated.create(allowed_projects, changeset |> Ecto.Changeset.apply_changes()) do
          {:ok, report} ->
            if Map.has_key?(consolidated_params, "download") do
              project = Gt.Repo.get!(Project, changeset.changes.project_id)
              filename = "#{changeset.changes.from}-#{changeset.changes.to}-#{project.item_id}.xlsx"
              conn
              |> put_resp_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
              |> put_resp_header("Content-Disposition", "attachment; filename=\"#{filename}\"")
              |> render("report.xlsx", report: report)
            else
              show_page(conn, params, changeset, user, report)
            end
          {:error, reason} ->
            Logger.error("Can't generate consolidated report #{reason}")
            conn
            |> put_flash(:info, gettext("unexpected_error"))
            |> redirect(to: consolidated_report_path(conn, :index))
        end
      else
        show_page(conn, params, changeset, user)
      end
    else
      show_page(conn, params, ConsolidatedModel.changeset(%ConsolidatedModel{}), user)
    end
  end

  defp show_page(conn, params, changeset, user, report \\ nil) do
    render conn, "index.html",
      changeset: changeset,
      projects: Project.options(Project, Project.allowed(user, "consolidated_report")),
      current_user: user,
      report: report,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
      ]
  end

  defp add_breadcrumb(conn, active \\ true) do
    [name: dgettext("menu", "consolidated_report")]
  end

end
