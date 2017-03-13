defmodule Gt.ConsolidatedReportControllerTest do
  use Gt.ConnCase

  alias Gt.ConsolidatedReport
  @valid_attrs %{}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, consolidated_report_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing consolidated reports"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, consolidated_report_path(conn, :new)
    assert html_response(conn, 200) =~ "New consolidated report"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, consolidated_report_path(conn, :create), consolidated_report: @valid_attrs
    assert redirected_to(conn) == consolidated_report_path(conn, :index)
    assert Repo.get_by(ConsolidatedReport, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, consolidated_report_path(conn, :create), consolidated_report: @invalid_attrs
    assert html_response(conn, 200) =~ "New consolidated report"
  end

  test "shows chosen resource", %{conn: conn} do
    consolidated_report = Repo.insert! %ConsolidatedReport{}
    conn = get conn, consolidated_report_path(conn, :show, consolidated_report)
    assert html_response(conn, 200) =~ "Show consolidated report"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, consolidated_report_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    consolidated_report = Repo.insert! %ConsolidatedReport{}
    conn = get conn, consolidated_report_path(conn, :edit, consolidated_report)
    assert html_response(conn, 200) =~ "Edit consolidated report"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    consolidated_report = Repo.insert! %ConsolidatedReport{}
    conn = put conn, consolidated_report_path(conn, :update, consolidated_report), consolidated_report: @valid_attrs
    assert redirected_to(conn) == consolidated_report_path(conn, :show, consolidated_report)
    assert Repo.get_by(ConsolidatedReport, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    consolidated_report = Repo.insert! %ConsolidatedReport{}
    conn = put conn, consolidated_report_path(conn, :update, consolidated_report), consolidated_report: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit consolidated report"
  end

  test "deletes chosen resource", %{conn: conn} do
    consolidated_report = Repo.insert! %ConsolidatedReport{}
    conn = delete conn, consolidated_report_path(conn, :delete, consolidated_report)
    assert redirected_to(conn) == consolidated_report_path(conn, :index)
    refute Repo.get(ConsolidatedReport, consolidated_report.id)
  end
end
