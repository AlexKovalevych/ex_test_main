defmodule Gt.PermissionsController do
  use Gt.Web, :controller

  import Gt.Auth.Permissions
  alias Gt.Project
  alias Gt.User
  require Logger

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :admin]

  def index(conn, %{"permissions" => permissions}, _current_user) do
    case Poison.decode(permissions["permissions"]) do
      {:ok, permissions} ->
        Enum.each(permissions, fn(%{"id" => id, "permissions" => userPermissions}) ->
          case Repo.get(User, id) do
            nil -> Logger.error("Couldn't update user #{id} permissions")
            user ->
              changeset = User.changeset(user, %{"permissions" => userPermissions})
              Repo.update!(changeset)
          end
        end)
        conn
        |> put_flash(:info, dgettext("permissions", "permissions_updated"))
        |> redirect(to: permissions_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> redirect(to: permissions_path(conn, :index))
    end
  end

  def index(conn, _params, current_user) do
    projects = Project
               |> Project.order_by_title
               |> Repo.all
    users = Repo.all(User)

    render conn, "index.html",
      current_user: current_user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        [name: dgettext("menu", "permissions")]
      ],
      permissions: %{
        users: Enum.map(users, fn user -> %{user | id: to_string(user.id)} end),
        roles: all_roles(),
        projects: Enum.map(projects, fn project -> %{project | id: to_string(project.id)} end),
      }
  end

  def export(conn, _, _) do
    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("Content-Disposition", "attachment; filename=\"permissions.csv\"")
    |> render("permissions.csv")
  end

end
