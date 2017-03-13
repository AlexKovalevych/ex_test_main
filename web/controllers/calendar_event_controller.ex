defmodule Gt.CalendarEventController do
  use Gt.Web, :controller

  alias Gt.CalendarEvent
  alias Gt.CalendarType
  alias Gt.Project
  import Ecto.Query

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :events_list]

  def index(conn, params, user) do
    {calendar_events, page} = CalendarEvent
                             |> CalendarEvent.allowed_events(user)
                             |> preload(:projects)
                             |> preload(:type)
                             |> preload(:user)
                             |> order_by([ce], desc: ce.id)
                             |> Repo.paginate(params)

    render conn, "index.html",
      page: page,
      calendar_events: calendar_events,
      current_user: user,
      projects: Project.options(Project, Project.allowed(user, "events_list")),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn, false)
      ]
  end

  def search(conn, %{"search" => %{"projects" => project_ids}} = params, user) do
    {calendar_events, page} = CalendarEvent
                              |> CalendarEvent.allowed_events(user, project_ids)
                              |> preload(:projects)
                              |> preload(:user)
                              |> preload(:type)
                              |> order_by(asc: :start_at)
                              |> Repo.paginate(params)
    render conn, "index.html",
      page: page,
      calendar_events: calendar_events,
      current_user: user,
      projects: Project.options(Project, Project.allowed(user, "events_list")),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn, false)
      ]
  end

  def search(conn, params, user) do
    index(conn, params, user)
  end

  def new(conn, _params, user) do
    changeset = CalendarEvent.changeset(%CalendarEvent{projects: []})
    render conn, "new.html",
      changeset: changeset,
      current_user: user,
      projects: Project.options(Project, Project.allowed(user, "events_list")),
      types: CalendarType.options(),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: dgettext("menu", "new_calendar_event")]
      ]
  end

  def create(conn, %{"calendar_event" => calendar_event_params}, user) do
    changeset = %CalendarEvent{user_id: user.id}
                |> CalendarEvent.changeset(calendar_event_params)

    case Repo.insert(changeset) do
      {:ok, calendar_event} ->
        conn
        |> put_flash(:info, dgettext("calendar_events", "event_updated", title: calendar_event.title))
        |> redirect(to: calendar_event_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          changeset: changeset,
          current_user: user,
          projects: Project.options(Project, Project.allowed(user, "events_list")),
          types: CalendarType.options(),
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: dgettext("menu", "new_calendar_event")]
          ],
        )
    end
  end

  def edit(conn, %{"id" => id}, user) do
    calendar_event = CalendarEvent
                     |> where([ce], ce.id == ^id)
                     |> CalendarEvent.allowed_events(user)
                     |> Repo.one!
                     |> Repo.preload(:projects)
                     |> Repo.preload(:type)
    calendar_event = Map.put(calendar_event, :project_ids, Enum.map(calendar_event.projects, fn %Project{id: id} -> id end))
    changeset = CalendarEvent.changeset(calendar_event)
    render conn, "edit.html",
      calendar_event: calendar_event,
      changeset: changeset,
      current_user: user,
      projects: Project.options(Project, Project.allowed(user, "events_list")),
      types: CalendarType.options(),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: calendar_event.title]
      ]
  end

  def update(conn, %{"id" => id, "calendar_event" => calendar_event_params}, user) do
    calendar_event = CalendarEvent
                     |> where([ce], ce.id == ^id)
                     |> CalendarEvent.allowed_events(user)
                     |> Repo.one!
                     |> Repo.preload(:projects)
                     |> Repo.preload(:type)
    changeset = CalendarEvent.changeset(calendar_event, calendar_event_params)

    case Repo.update(changeset) do
      {:ok, calendar_event} ->
        conn
        |> put_flash(:info, dgettext("calendar_events", "event_updated", title: calendar_event.title))
        |> redirect(to: calendar_event_path(conn, :edit, calendar_event))
      {:error, changeset} ->
        render conn, "edit.html",
          changeset: changeset,
          calendar_event: calendar_event,
          current_user: user,
          projects: Project.options(Project, Project.allowed(user, "events_list")),
          types: CalendarType.options(),
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: calendar_event.title]
          ]
    end
  end

  def delete(conn, %{"id" => id}, user) do
    calendar_event = CalendarEvent
                     |> where([ce], ce.id == ^id)
                     |> CalendarEvent.allowed_events(user)
                     |> Repo.one!

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(calendar_event)

    conn
    |> put_flash(:info, dgettext("calendar_events", "event_deleted"))
    |> redirect(to: calendar_event_path(conn, :index))
  end

  defp add_breadcrumb(conn, active \\ true) do
    breadcrumb = [name: dgettext("menu", "calendar_events")]
    if active do
      Keyword.put(breadcrumb, :url, calendar_event_path(conn, :index))
    else
      breadcrumb
    end
  end

end
