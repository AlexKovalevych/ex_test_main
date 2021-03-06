defmodule Gt.PaymentCheckControllerTest do
  use Gt.ConnCase

  alias Gt.PaymentCheck
  @valid_attrs %{active: true, completed: true, files: [], processed: 42, total: 42}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, payment_check_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing payment checks"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, payment_check_path(conn, :new)
    assert html_response(conn, 200) =~ "New payment check"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, payment_check_path(conn, :create), payment_check: @valid_attrs
    assert redirected_to(conn) == payment_check_path(conn, :index)
    assert Repo.get_by(PaymentCheck, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, payment_check_path(conn, :create), payment_check: @invalid_attrs
    assert html_response(conn, 200) =~ "New payment check"
  end

  test "shows chosen resource", %{conn: conn} do
    payment_check = Repo.insert! %PaymentCheck{}
    conn = get conn, payment_check_path(conn, :show, payment_check)
    assert html_response(conn, 200) =~ "Show payment check"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, payment_check_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    payment_check = Repo.insert! %PaymentCheck{}
    conn = get conn, payment_check_path(conn, :edit, payment_check)
    assert html_response(conn, 200) =~ "Edit payment check"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    payment_check = Repo.insert! %PaymentCheck{}
    conn = put conn, payment_check_path(conn, :update, payment_check), payment_check: @valid_attrs
    assert redirected_to(conn) == payment_check_path(conn, :show, payment_check)
    assert Repo.get_by(PaymentCheck, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    payment_check = Repo.insert! %PaymentCheck{}
    conn = put conn, payment_check_path(conn, :update, payment_check), payment_check: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit payment check"
  end

  test "deletes chosen resource", %{conn: conn} do
    payment_check = Repo.insert! %PaymentCheck{}
    conn = delete conn, payment_check_path(conn, :delete, payment_check)
    assert redirected_to(conn) == payment_check_path(conn, :index)
    refute Repo.get(PaymentCheck, payment_check.id)
  end
end
