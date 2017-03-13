defmodule Gt.DataSourceController do
  use Gt.Web, :controller

  alias Gt.DataSource
  alias Gt.Project
  alias Gt.DataSourceServer
  import Ecto.Query
  require Logger

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :admin]

  def index(conn, params, user) do
    {data_sources, page} = DataSource
                     |> order_by([ds], desc: ds.updated_at)
                     |> preload(:project)
                     |> Repo.paginate(params)

    render conn, "index.html",
      page: page,
      current_user: user,
      data_sources: data_sources,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn, false),
      ]
  end

  def new(conn, %{"type" => type}, user) do
    changeset = DataSource.changeset(%DataSource{type: type})
    render conn, "new.html",
      changeset: changeset,
      current_user: user,
      projects: Project.options(),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: dgettext("menu", "new_data_source")]
      ]
  end

  def create(conn, %{"type" => type, "data_source" => data_source_params}, user) do
    changeset = DataSource.changeset(%DataSource{type: type}, data_source_params)

    case Repo.insert(changeset) do
      {:ok, data_source} ->
        conn
        |> put_flash(:info, dgettext("data_sources", "data_source_created"))
        |> redirect(to: data_source_path(conn, :edit, data_source))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          changeset: changeset,
          current_user: user,
          projects: Project.options(),
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: dgettext("menu", "new_data_source")]
          ]
        )
    end
  end

  def create(conn, %{"type" => type, "file" => data_source_params}, user) do
    changeset = DataSource.changeset(%DataSource{type: type}, Map.put(data_source_params, "is_files", true))

    case Repo.insert(changeset) do
      {:ok, data_source} ->
        files = data_source_params["files"]
          |> Enum.map(&Gt.Uploaders.DataSource.store({&1, data_source}))
          |> Enum.filter_map(
            fn res ->
              case res do
                {:ok, _} -> true
                _ -> false
              end
            end,
            fn {:ok, path} -> path end
          )
        data_source
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.cast(%{files: files}, [:files])
        |> Repo.update!
        conn
        |> put_flash(:info, dgettext("data_sources", "data_source_created"))
        |> redirect(to: data_source_path(conn, :edit, data_source))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          is_files: true,
          changeset: changeset,
          current_user: user,
          projects: Project.options(),
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: dgettext("menu", "new_data_source")]
          ]
        )
    end
  end

  def edit(conn, %{"id" => id}, user) do
    data_source = Repo.get!(DataSource, id)
    changeset = DataSource.changeset(data_source)
    render conn, "edit.html",
      data_source: data_source,
      changeset: changeset,
      current_user: user,
      projects: Project.options(),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: data_source.name]
      ]
  end

  def start(conn, %{"id" => id}, _user) do
    data_source = Repo.get!(DataSource, id)
    case DataSourceServer.add_worker(data_source) do
      {:ok, pid} ->
        GenServer.cast(pid, String.to_atom(data_source.type))
        conn
        |> put_flash(:info, gettext("worker_started"))
        |> redirect(to: data_source_path(conn, :edit, data_source))
      {:error, {:already_started, _pid}} ->
        redirect conn, to: data_source_path(conn, :edit, data_source)
      {:error, reason} ->
        Logger.error("Failed to start data_source worker: #{reason}")
        conn
        |> put_flash(:error, gettext("unexpected_error"))
        |> redirect(to: data_source_path(conn, :edit, data_source))
    end
  end

  def stop(conn, %{"id" => id}, _user) do
    data_source = Repo.get!(DataSource, id)
    case DataSourceServer.stop_worker(data_source) do
      :ok ->
        conn
        |> put_flash(:info, gettext("worker_stopped"))
        |> redirect(to: data_source_path(conn, :edit, data_source))
      {:error, reason} ->
        Logger.error("Failed to stop data_source worker: #{reason}")
        conn
        |> put_flash(:info, gettext("worker_stopped"))
        |> redirect(to: data_source_path(conn, :edit, data_source))
    end
  end

  def update(conn, %{"id" => id, "data_source" => data_source_params}, user) do
    data_source = Repo.get!(DataSource, id)
    changeset = DataSource.changeset(data_source, data_source_params)

    case Repo.update(changeset) do
      {:ok, data_source} ->
        conn
        |> put_flash(:info, dgettext("data_sources", "data_source_worker_update", id: data_source.id))
        |> redirect(to: data_source_path(conn, :edit, data_source))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("edit.html",
          data_source: data_source,
          changeset: changeset,
          current_user: user,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: data_source.name]
          ]
        )
    end
  end

  def delete(conn, %{"id" => id}, _user) do
    data_source = Repo.get!(DataSource, id)
    if DataSource.is_started(data_source) do
      conn
      |> put_flash(:error, gettext("cant_delete_active_worker"))
      |> redirect(to: data_source_path(conn, :edit, data_source))
    else
      Repo.delete!(data_source)
      conn
      |> put_flash(:info, gettext("worker_deleted"))
      |> redirect(to: data_source_path(conn, :index))
    end
  end

  defp add_breadcrumb(conn, active \\ true) do
    breadcrumb = [name: dgettext("menu", "data_sources")]
    if active do
      Keyword.put(breadcrumb, :url, data_source_path(conn, :index))
    else
      breadcrumb
    end
  end

end
