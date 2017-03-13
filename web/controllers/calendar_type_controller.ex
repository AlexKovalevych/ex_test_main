defmodule Gt.CalendarTypeController do
  use Gt.Web, :controller

  alias Gt.CalendarType
  alias Gt.CalendarGroup

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :events_types_list]

  def index(conn, params, user) do
    {calendar_types, page} = CalendarType
                             |> Ecto.Query.preload(:group)
                             |> Repo.paginate(params)

    render conn, "index.html",
      page: page,
      calendar_types: calendar_types,
      current_user: user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn, false)
      ]
  end

  def new(conn, _params, user) do
    changeset = CalendarType.changeset(%CalendarType{})
    render conn, "new.html",
      changeset: changeset,
      current_user: user,
      groups: get_groups(),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: dgettext("menu", "new_calendar_type")]
      ]
  end

  def create(conn, %{"calendar_type" => calendar_type_params}, user) do
    changeset = CalendarType.changeset(%CalendarType{}, calendar_type_params)

    case Repo.insert(changeset) do
      {:ok, calendar_type} ->
        conn
        |> put_flash(:info, dgettext("calendar_types", "type_updated", name: calendar_type.name))
        |> redirect(to: calendar_type_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          changeset: changeset,
          current_user: user,
          groups: get_groups(),
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: dgettext("menu", "new_calendar_type")]
          ],
        )
    end
  end

  def edit(conn, %{"id" => id}, user) do
    calendar_type = Repo.get!(CalendarType, id) |> Repo.preload(:group)
    changeset = CalendarType.changeset(calendar_type)
    render conn, "edit.html",
      changeset: changeset,
      calendar_type: calendar_type,
      current_user: user,
      groups: get_groups(),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: calendar_type.name]
      ]
  end

  def update(conn, %{"id" => id, "calendar_type" => calendar_type_params}, user) do
    calendar_type = Repo.get!(CalendarType, id)
    changeset = CalendarType.changeset(calendar_type, calendar_type_params)

    case Repo.update(changeset) do
      {:ok, calendar_type} ->
        conn
        |> put_flash(:info, dgettext("calendar_types", "type_updated", name: calendar_type.name))
        |> redirect(to: calendar_type_path(conn, :edit, calendar_type))
      {:error, changeset} ->
        render conn, "edit.html",
          changeset: changeset,
          calendar_type: calendar_type,
          current_user: user,
          groups: get_groups(),
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: calendar_type.name]
          ]
    end
  end

  def delete(conn, %{"id" => id}, _user) do
    calendar_type = Repo.get!(CalendarType, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(calendar_type)

    conn
    |> put_flash(:info, dgettext("calendar_types", "type_deleted"))
    |> redirect(to: calendar_type_path(conn, :index))
  end

  defp get_groups() do
    CalendarGroup
    |> Repo.all
    |> Enum.map(fn %CalendarGroup{name: name, id: id} ->
      {name, id}
    end)
  end

  defp add_breadcrumb(conn, active \\ true) do
    breadcrumb = [name: dgettext("menu", "event_types")]
    if active do
      Keyword.put(breadcrumb, :url, calendar_type_path(conn, :index))
    else
      breadcrumb
    end
  end

end
