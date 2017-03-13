defmodule Gt.CacheController do
  use Gt.Web, :controller

  alias Gt.Cache
  alias Gt.Project
  alias Gt.CacheServer
  import Ecto.Query
  require Logger

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :admin]

  def index(conn, params, user) do
    projects = Repo.all(Project)
               |> Enum.into(%{}, fn project -> {project.id, project} end)

    {caches, page} = Cache
                     |> order_by([c], desc: c.updated_at)
                     |> Repo.paginate(params)
    caches = Enum.map(caches, fn cache ->
               %{cache | projects: Enum.map(cache.projects, fn cache_project ->
                 projects[cache_project]
               end)}
             end)
    render conn, "index.html",
           page: page,
           caches: caches,
           current_user: user,
           breadcrumbs: [
             Gt.DashboardController.add_breadcrumb(conn),
             add_breadcrumb(conn, false),
           ]
  end

  def new(conn, %{"type" => type}, user) do
    changeset = Cache.changeset(%Cache{projects: [], type: type})
    render conn, "new.html",
      changeset: changeset,
      current_user: user,
      projects: Project.options(),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: dgettext("menu", "new_cache_worker")]
      ]
  end

  def create(conn, %{"type" => type, "cache" => cache_params}, user) do
    changeset = Cache.changeset(%Cache{type: type}, cache_params)

    case Repo.insert(changeset) do
      {:ok, cache} ->
        conn
        |> put_flash(:info, dgettext("cache", "cache_worker_created"))
        |> redirect(to: cache_path(conn, :edit, cache))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          changeset: changeset,
          current_user: user,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: dgettext("menu", "new_cache_worker")]
          ]
        )
    end
  end

  def create(conn, %{"type" => _type} = params, user) do
    create(conn, Map.put(params, "cache", %{}), user)
  end

  def edit(conn, %{"id" => id}, user) do
    cache = Repo.get!(Cache, id)
    changeset = Cache.changeset(cache)
    render conn, "edit.html",
      cache: cache,
      changeset: changeset,
      current_user: user,
      projects: Project.options(),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: dgettext("menu", "edit_cache_worker", id: cache.id)]
      ]
  end

  def start(conn, %{"id" => id}, _user) do
    cache = Repo.get!(Cache, id)
    case CacheServer.add_worker(cache) do
      {:ok, pid} ->
        GenServer.cast(pid, String.to_atom(cache.type))
        conn
        |> put_flash(:info, gettext("worker_started"))
        |> redirect(to: cache_path(conn, :edit, cache))
      {:error, {:already_started, _pid}} ->
        redirect conn, to: cache_path(conn, :edit, cache)
      {:error, reason} ->
        Logger.error("Failed to start cache worker: #{reason}")
        conn
        |> put_flash(:error, gettext("unexpected_error"))
        |> redirect(to: cache_path(conn, :edit, cache))
    end
  end

  def stop(conn, %{"id" => id}, _user) do
    cache = Repo.get!(Cache, id)
    case CacheServer.stop_worker(cache) do
      :ok ->
        conn
        |> put_flash(:info, gettext("worker_stopped"))
        |> redirect(to: cache_path(conn, :edit, cache))
      {:error, reason} ->
        Logger.error("Failed to stop cache worker: #{reason}")
        conn
        |> put_flash(:info, gettext("worker_stopped"))
        |> redirect(to: cache_path(conn, :edit, cache))
    end
  end

  def update(conn, %{"id" => id, "cache" => cache_params}, user) do
    cache = Repo.get!(Cache, id)
    changeset = Cache.changeset(cache, cache_params)

    case Repo.update(changeset) do
      {:ok, cache} ->
        conn
        |> put_flash(:info, dgettext("cache", "cache_worker_update", id: cache.id))
        |> redirect(to: cache_path(conn, :edit, cache))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("edit.html",
          cache: cache,
          changeset: changeset,
          current_user: user,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: cache.id]
          ]
        )
    end
  end

  def delete(conn, %{"id" => id}, _user) do
    cache = Repo.get!(Cache, id)
    if Cache.is_started(cache) do
      conn
      |> put_flash(:error, gettext("cant_delete_active_worker"))
      |> redirect(to: cache_path(conn, :edit, cache))
    else
      Repo.delete!(cache)
      conn
      |> put_flash(:info, gettext("worker_deleted"))
      |> redirect(to: cache_path(conn, :index))
    end
  end

  defp add_breadcrumb(conn, active \\ true) do
    breadcrumb = [name: dgettext("menu", "cache")]
    if active do
      Keyword.put(breadcrumb, :url, cache_path(conn, :index))
    else
      breadcrumb
    end
  end

end
