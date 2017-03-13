defmodule Gt.PaymentSystemControllerTest do
  use Gt.ConnCase

  alias Gt.PaymentSystem
  @valid_attrs %{}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, payment_system_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing payment systems"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, payment_system_path(conn, :new)
    assert html_response(conn, 200) =~ "New payment system"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, payment_system_path(conn, :create), payment_system: @valid_attrs
    assert redirected_to(conn) == payment_system_path(conn, :index)
    assert Repo.get_by(PaymentSystem, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, payment_system_path(conn, :create), payment_system: @invalid_attrs
    assert html_response(conn, 200) =~ "New payment system"
  end

  test "shows chosen resource", %{conn: conn} do
    payment_system = Repo.insert! %PaymentSystem{}
    conn = get conn, payment_system_path(conn, :show, payment_system)
    assert html_response(conn, 200) =~ "Show payment system"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, payment_system_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    payment_system = Repo.insert! %PaymentSystem{}
    conn = get conn, payment_system_path(conn, :edit, payment_system)
    assert html_response(conn, 200) =~ "Edit payment system"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    payment_system = Repo.insert! %PaymentSystem{}
    conn = put conn, payment_system_path(conn, :update, payment_system), payment_system: @valid_attrs
    assert redirected_to(conn) == payment_system_path(conn, :show, payment_system)
    assert Repo.get_by(PaymentSystem, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    payment_system = Repo.insert! %PaymentSystem{}
    conn = put conn, payment_system_path(conn, :update, payment_system), payment_system: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit payment system"
  end

  test "deletes chosen resource", %{conn: conn} do
    payment_system = Repo.insert! %PaymentSystem{}
    conn = delete conn, payment_system_path(conn, :delete, payment_system)
    assert redirected_to(conn) == payment_system_path(conn, :index)
    refute Repo.get(PaymentSystem, payment_system.id)
  end
end
