defmodule Gt.CalendarGroupController do
  use Gt.Web, :controller

  alias Gt.CalendarGroup

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :events_groups_list]

  def index(conn, params, user) do
    {calendar_groups, page} = CalendarGroup |> Repo.paginate(params)

    render conn, "index.html",
      page: page,
      calendar_groups: calendar_groups,
      current_user: user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn, false)
      ]
  end

  def new(conn, _params, user) do
    changeset = CalendarGroup.changeset(%CalendarGroup{})
    render conn, "new.html",
      changeset: changeset,
      current_user: user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: dgettext("menu", "new_calendar_group")]
      ]
  end

  def create(conn, %{"calendar_group" => calendar_group_params}, user) do
    changeset = CalendarGroup.changeset(%CalendarGroup{}, calendar_group_params)

    case Repo.insert(changeset) do
      {:ok, calendar_group} ->
        conn
        |> put_flash(:info, dgettext("calendar_groups", "group_updated", name: calendar_group.name))
        |> redirect(to: calendar_group_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          changeset: changeset,
          current_user: user,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: dgettext("menu", "new_calendar_group")]
          ],
        )
    end
  end

  def edit(conn, %{"id" => id}, user) do
    calendar_group = Repo.get!(CalendarGroup, id)
    changeset = CalendarGroup.changeset(calendar_group)
    render conn, "edit.html",
      calendar_group: calendar_group,
      current_user: user,
      changeset: changeset,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: calendar_group.name]
      ]
  end

  def update(conn, %{"id" => id, "calendar_group" => calendar_group_params}, user) do
    calendar_group = Repo.get!(CalendarGroup, id)
    changeset = CalendarGroup.changeset(calendar_group, calendar_group_params)

    case Repo.update(changeset) do
      {:ok, calendar_group} ->
        conn
        |> put_flash(:info, dgettext("calendar_groups", "group_updated", name: calendar_group.name))
        |> redirect(to: calendar_group_path(conn, :edit, calendar_group))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          changeset: changeset,
          calendar_group: calendar_group,
          current_user: user,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: calendar_group.name]
          ],
        )
    end
  end

  def delete(conn, %{"id" => id}, _user) do
    calendar_group = Repo.get!(CalendarGroup, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(calendar_group)

    conn
    |> put_flash(:info, dgettext("calendar_groups", "group_deleted"))
    |> redirect(to: calendar_group_path(conn, :index))
  end

  defp add_breadcrumb(conn, active \\ true) do
    breadcrumb = [name: dgettext("menu", "event_groups")]
    if active do
      Keyword.put(breadcrumb, :url, calendar_group_path(conn, :index))
    else
      breadcrumb
    end
  end

end
