defmodule Gt.UserController do
  use Gt.Web, :controller

  import Ecto.Query
  import Gt.Auth.Permissions
  alias Gt.Project
  alias Gt.UserSettings
  alias Gt.User

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :admin]

  def index(conn, params, user) do
    {users, page} = User
            |> order_by(asc: :email)
            |> Repo.paginate(params)
    render conn, "index.html",
      page: page,
      users: users,
      current_user: user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn, false)
      ]
  end

  def search(conn, %{"query" => query} = params, user) do
    {users, page} = User
            |> where([u], ilike(u.email, ^"%#{query}%"))
            |> order_by(asc: :email)
            |> Repo.paginate(params)
    render conn, "index.html",
      page: page,
      users: users,
      current_user: user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn, false)
      ]
  end

  def new(conn, _params, current_user) do
    changeset = User.changeset(%User{})
    render conn, "new.html",
      changeset: changeset,
      current_user: current_user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: dgettext("menu", "new_user")]
      ],
      permissions: permissions()
  end

  def create(conn, %{"user" => user_params}, current_user) do
    user_params = %{user_params | "permissions" => Poison.decode!(user_params["permissions"])["permissions"]}
    changeset = User.new_changeset(%User{}, user_params)
    |> Ecto.Changeset.put_assoc(:settings, UserSettings.changeset(%UserSettings{}))

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, dgettext("users", "user_updated", email: user.email))
        |> redirect(to: user_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          changeset: changeset,
          current_user: current_user,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: dgettext("menu", "new_user")]
          ],
          permissions: permissions()
        )
    end
  end

  def edit(conn, %{"id" => id}, current_user) do
    user = Repo.get!(User, id)
    changeset = User.changeset(user)
    render conn, "edit.html",
      user: user,
      current_user: current_user,
      changeset: changeset,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: user.email]
      ],
      permissions: permissions(user)
  end

  def update(conn, %{"id" => id, "user" => user_params}, current_user) do
    user = Repo.get!(User, id)
    user_params = %{user_params | "permissions" => Poison.decode!(user_params["permissions"])["permissions"]}
    changeset = User.changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, dgettext("users", "user_updated", email: user.email))
        |> redirect(to: user_path(conn, :edit, user.id))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("edit.html", user: user,
          changeset: changeset,
          current_user: current_user,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: user.email]
          ],
          permissions: permissions(user)
        )
    end
  end

  defp add_breadcrumb(conn, active \\ true) do
    breadcrumb = [name: dgettext("menu", "users")]
    if active do
      Keyword.put(breadcrumb, :url, user_path(conn, :index))
    else
      breadcrumb
    end
  end

  defp permissions(user \\ nil) do
    projects = Project |> order_by(asc: :title) |> Repo.all
    permissions = Application.get_env(:gt, :permissions)
    project_ids = Enum.map(projects, fn project -> project.id end)
    user = if is_nil(user), do: %User{permissions: add(permissions, Map.keys(permissions), project_ids)}, else: user
    %{
      users: [ %{user | id: to_string(user.id)} ],
      roles: all_roles(),
      projects: Enum.map(projects, fn project -> %{project| id: to_string(project.id)} end),
    }
  end

end
