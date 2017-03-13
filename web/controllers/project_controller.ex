defmodule Gt.ProjectController do
  use Gt.Web, :controller

  import Ecto.Query
  alias Gt.Project

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :admin]

  def index(conn, params, user) do
    {projects, page} = Project
            |> order_by(asc: :title)
            |> Repo.paginate(params)
    render conn, "index.html",
      page: page,
      projects: projects,
      current_user: user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn, false)
      ]
  end

  def search(conn, %{"query" => query} = params, user) do
    {projects, page} = Project
            |> where([u], ilike(u.title, ^"%#{query}%"))
            |> order_by(asc: :title)
            |> Repo.paginate(params)
    render conn, "index.html",
      page: page,
      projects: projects,
      current_user: user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn, false)
      ]
  end

  def new(conn, _params, user) do
    changeset = Project.changeset(%Project{})
    render conn, "new.html",
      changeset: changeset,
      current_user: user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: dgettext("menu", "new_project")]
      ]
  end

  def create(conn, %{"project" => project_params}, user) do
    changeset = Project.changeset(%Project{}, project_params)

    case Repo.insert(changeset) do
      {:ok, project} ->
        conn
        |> put_flash(:info, dgettext("projects", "project_updated", title: project.title))
        |> redirect(to: project_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          changeset: changeset,
          current_user: user,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: dgettext("menu", "new_project")]
          ]
        )
    end
  end

  def edit(conn, %{"id" => id}, user) do
    project = Repo.get!(Project, id)
    changeset = Project.changeset(project)
    render conn, "edit.html",
      project: project,
      current_user: user,
      changeset: changeset,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: project.title]
      ]
  end

  def update(conn, %{"id" => id, "project" => project_params}, user) do
    project = Repo.get!(Project, id)
    changeset = Project.changeset(project, project_params)

    case Repo.update(changeset) do
      {:ok, project} ->
        conn
        |> put_flash(:info, dgettext("projects", "project_updated", title: project.title))
        |> redirect(to: project_path(conn, :edit, project.id))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("edit.html",
          current_user: user,
          project: project,
          changeset: changeset,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: project.title]
          ]
        )
    end
  end

  defp add_breadcrumb(conn, active \\ true) do
    breadcrumb = [name: dgettext("menu", "projects")]
    if active do
      Keyword.put(breadcrumb, :url, project_path(conn, :index))
    else
      breadcrumb
    end
  end

end
