defmodule Gt.PaymentCheckController do
  use Gt.Web, :controller

  alias Gt.Report.PaymentCheckOneS
  alias Gt.PaymentCheck
  alias Gt.PaymentSystem
  alias Gt.PaymentCheckTransaction
  alias Gt.PaymentCheckServer
  import Ecto.Query
  require Logger

  plug EnsureAuthenticated, [handler: Gt.SessionController, permission: :payments_check]

  def index(conn, params, user) do
    {payment_checks, page} = PaymentCheck
                             |> order_by([pc], asc: pc.updated_at)
                             |> preload(:payment_system)
                             |> preload(:user)
                             |> Repo.paginate(params)
    render conn, "index.html",
           page: page,
           payment_checks: payment_checks,
           current_user: user,
           breadcrumbs: [
             Gt.DashboardController.add_breadcrumb(conn),
             add_breadcrumb(conn, false),
           ]
  end

  def new(conn, _params, user) do
    changeset = PaymentCheck.changeset(%PaymentCheck{})
    render conn, "new.html",
      changeset: changeset,
      current_user: user,
      payment_systems: PaymentSystem.options(),
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: dgettext("menu", "new_payment_check")]
      ]
  end

  def create(conn, %{"payment_check" => payment_check_params}, user) do
    payment_system = PaymentSystem
                     |> Repo.get!(payment_check_params["payment_system_id"])
                     |> Map.from_struct()
                     |> Map.delete(:__meta__)

    changeset = %PaymentCheck{user_id: user.id}
                |> PaymentCheck.changeset(payment_check_params)
                |> Ecto.Changeset.put_change(:ps, payment_system)

    case Repo.insert(changeset) do
      {:ok, payment_check} ->
        files = payment_check_params["files"]
          |> Enum.map(&Gt.Uploaders.PaymentCheck.store({&1, payment_check}))
          |> Enum.filter_map(
            fn res ->
              case res do
                {:ok, _} -> true
                _ -> false
              end
            end,
            fn {:ok, path} -> path end
          )
        payment_check = payment_check
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.cast(%{files: files}, [:files])
        |> Repo.update!
        case PaymentCheckServer.add_worker(payment_check) do
          {:ok, pid} ->
            GenServer.cast(pid, :run)
            conn
            |> put_flash(:info, gettext("worker_started"))
            |> redirect(to: payment_check_path(conn, :show, payment_check))
          {:error, {:already_started, _pid}} ->
            redirect conn, to: payment_check_path(conn, :show, payment_check)
          {:error, reason} ->
            Logger.error("Failed to start payment check worker: #{reason}")
            conn
            |> put_flash(:error, gettext("unexpected_error"))
            |> redirect(to: payment_check_path(conn, :show, payment_check))
        end
      {:error, changeset} ->
        conn
        |> put_flash(:error, gettext("validation_failed"))
        |> render("new.html",
          changeset: changeset,
          current_user: user,
          payment_systems: PaymentSystem.options(),
          breadcrumbs: [
            Gt.DashboardController.add_breadcrumb(conn),
            add_breadcrumb(conn),
            [name: dgettext("menu", "new_payment_check")]
          ],
        )
    end
  end

  def start(conn, %{"id" => id}, _user) do
    payment_check = Repo.get!(PaymentCheck, id)
    case PaymentCheckServer.add_worker(payment_check) do
      {:ok, pid} ->
        GenServer.cast(pid, :run)
        conn
        |> put_flash(:info, gettext("worker_started"))
        |> redirect(to: payment_check_path(conn, :show, payment_check))
      {:error, {:already_started, _pid}} ->
        redirect conn, to: payment_check_path(conn, :show, payment_check)
      {:error, reason} ->
        Logger.error("Failed to start payment_check worker: #{reason}")
        conn
        |> put_flash(:error, gettext("unexpected_error"))
        |> redirect(to: payment_check_path(conn, :show, payment_check))
    end
  end

  def stop(conn, %{"id" => id}, _user) do
    payment_check = Repo.get!(PaymentCheck, id)
    case PaymentCheckServer.stop_worker(payment_check) do
      :ok ->
        conn
        |> put_flash(:info, gettext("worker_stopped"))
        |> redirect(to: payment_check_path(conn, :show, payment_check))
      {:error, reason} ->
        Logger.error("Failed to stop payment_check worker: #{reason}")
        conn
        |> put_flash(:info, gettext("worker_stopped"))
        |> redirect(to: payment_check_path(conn, :show, payment_check))
    end
  end

  def show(conn, %{"id" => id} = params, user) do
    payment_check = Repo.get!(PaymentCheck, id)
                    |> Repo.preload(:payment_system)
                    |> Repo.preload(:user)
    if Map.has_key?(params, "one_s") do
      one_s_params = params["one_s"]
      changeset = one_s_changeset(one_s_params)
      if changeset.valid? do
        stats = PaymentCheckTransaction.stats(payment_check.id) |> Repo.one!
        conn
        |> put_resp_content_type("text/csv")
        |> put_resp_header("Content-Disposition", "attachment; filename=\"#{filename(payment_check, stats, "check-report")}\"")
        |> render("1c.csv", payment_check: payment_check, one_s: changeset |> Ecto.Changeset.apply_changes())
      else
        show_page(conn, params, payment_check, user)
      end
    else
      show_page(conn, params, payment_check, user)
    end
  end

  def delete(conn, %{"id" => id}, _user) do
    payment_check = Repo.get!(PaymentCheck, id)

    if PaymentCheck.is_started(payment_check) do
      conn
      |> put_flash(:error, gettext("cant_delete_active_worker"))
      |> redirect(to: payment_check_path(conn, :show, payment_check))
    else
      Repo.delete!(payment_check)
      conn
      |> put_flash(:info, gettext("worker_deleted"))
      |> redirect(to: payment_check_path(conn, :index))
    end
  end

  def one_gamepay_errors(conn, %{"id" => id}, _user) do
    payment_check = Repo.get!(PaymentCheck, id)
                    |> Repo.preload(:payment_system)
    case PaymentCheck.is_completed(payment_check) do
      true ->
        stats = PaymentCheckTransaction.stats(payment_check.id) |> Repo.one!
        conn
        |> put_resp_content_type("text/csv")
        |> put_resp_header("Content-Disposition", "attachment; filename=\"#{filename(payment_check, stats, "errors-onegamepay")}\"")
        |> render("1gp.csv", %{payment_check: payment_check})
      _ ->
        conn |> redirect(to: payment_check_path(conn, :show, payment_check))
    end
  end

  defp add_breadcrumb(conn, active \\ true) do
    breadcrumb = [name: dgettext("menu", "payment_checks")]
    if active do
      Keyword.put(breadcrumb, :url, payment_check_path(conn, :index))
    else
      breadcrumb
    end
  end

  defp filename(payment_check, %{from: from, to: to}, suffix) do
    "#{payment_check.payment_system.name}-#{from |> Gt.Date.format(:date)}-#{to |> Gt.Date.format(:date)}-#{suffix}.csv"
  end

  defp one_s_changeset(params) do
    %PaymentCheckOneS{}
    |> PaymentCheckOneS.changeset(params)
    |> Map.put(:action, :insert)
  end

  defp show_page(conn, params, payment_check, user) do
    report = case PaymentCheck.is_completed(payment_check) do
      true ->
        tab = Map.get(params, "tab", "1") |> String.to_integer
        one_gamepay_page = if tab == 2, do: Map.get(params, "page", "1") |> String.to_integer, else: 1
        {transactions, page} = PaymentCheckTransaction
        |> PaymentCheckTransaction.by_payment_check(payment_check.id)
        |> PaymentCheckTransaction.one_gamepay_errors()
        |> Ecto.Query.preload(:one_gamepay_transaction)
        |> Repo.paginate(%{"page" => one_gamepay_page})

        transactions = transactions
        |> Enum.map(fn transaction ->
          Enum.zip(Gt.Report.PaymentCheck.one_gamepay_fields(), Gt.Report.PaymentCheck.one_gamepay_error(transaction))
          |> Map.new
        end)
        stats = PaymentCheckTransaction.stats(payment_check.id) |> Repo.one!
        urls = if is_nil(stats.urls), do: [], else: stats.urls
        default_one_s = %{
          "from" => stats.from,
          "to" => stats.to,
          "urls" => urls
        }
        %Gt.Report.PaymentCheck{
          stats: stats,
          tab: tab,
          one_gamepay_errors: transactions,
          one_gamepay_page: page,
          one_s_changeset: Map.get(params, "one_s", default_one_s) |> one_s_changeset()
        }
      _ ->
        %Gt.Report.PaymentCheck{}
    end
    changeset = PaymentCheck.changeset(payment_check)
    render conn, "show.html",
      changeset: changeset,
      payment_check: payment_check,
      report: report,
      payment_systems: PaymentSystem.options(),
      current_user: user,
      breadcrumbs: [
        Gt.DashboardController.add_breadcrumb(conn),
        add_breadcrumb(conn),
        [name: payment_check.payment_system.name]
      ]
  end

end
