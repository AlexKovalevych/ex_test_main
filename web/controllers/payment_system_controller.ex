defmodule Gt.PaymentSystemController do
  use Gt.Web, :controller

  alias Gt.PaymentSystem
  import Ecto.Query

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :payment_systems]

  def index(conn, params, user) do
    {payment_systems, page} = PaymentSystem
                              |> order_by([ps], asc: ps.name)
                              |> Repo.paginate(params)
    render conn, "index.html",
           page: page,
           payment_systems: payment_systems,
           current_user: user,
           breadcrumbs: [
             Gt.DashboardController.add_breadcrumb(conn),
             add_breadcrumb(conn, false),
           ]
  end

  def new(conn, %{"type" => type}, user) do
    script = if type != "default", do: type, else: nil
    changeset = PaymentSystem.changeset(%PaymentSystem{script: script})
    render conn, "new.html",
      changeset: changeset,
      type: type,
      current_user: user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: dgettext("menu", "new_payment_system")]
      ]
  end

  def create(conn, %{"type" => type, "payment_system" => payment_system_params}, user) do
    script = if type != "default", do: type, else: nil
    changeset = PaymentSystem.changeset(%PaymentSystem{script: script}, payment_system_params)

    case Repo.insert(changeset) do
      {:ok, payment_system} ->
        conn
        |> put_flash(:info, dgettext("payment_systems", "payment_system_updated", name: payment_system.name))
        |> redirect(to: payment_system_path(conn, :index))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          changeset: changeset,
          type: type,
          current_user: user,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: dgettext("menu", "new_payment_system")]
          ]
        )
    end
  end

  def edit(conn, %{"id" => id}, user) do
    payment_system = Repo.get!(PaymentSystem, id)
    changeset = PaymentSystem.changeset(payment_system)
    render conn, "edit.html",
      payment_system: payment_system,
      type: payment_system.script,
      current_user: user,
      changeset: changeset,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: payment_system.name]
      ]
  end

  def update(conn, %{"id" => id, "payment_system" => payment_system_params}, user) do
    payment_system = Repo.get!(PaymentSystem, id)
    changeset = PaymentSystem.changeset(payment_system, payment_system_params)

    case Repo.update(changeset) do
      {:ok, payment_system} ->
        conn
        |> put_flash(:info, dgettext("payment_systems", "payment_system_updated", title: payment_system.name))
        |> redirect(to: payment_system_path(conn, :edit, payment_system.id))
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("edit.html",
          current_user: user,
          type: payment_system.script,
          payment_system: payment_system,
          changeset: changeset,
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: payment_system.name]
          ]
        )
    end
  end

  def copy(conn, %{"id" => id}, _user) do
    payment_system = Repo.get!(PaymentSystem, id)
    IO.inspect(payment_system)
  end

  def delete(conn, %{"id" => id}, _user) do
    payment_system = Repo.get!(PaymentSystem, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(payment_system)

    conn
    |> put_flash(:info, dgettext("payment_systems", "payment_system_deleted"))
    |> redirect(to: payment_system_path(conn, :index))
  end

  defp add_breadcrumb(conn, active \\ true) do
    breadcrumb = [name: dgettext("menu", "payment_systems")]
    if active do
      Keyword.put(breadcrumb, :url, payment_system_path(conn, :index))
    else
      breadcrumb
    end
  end

end
