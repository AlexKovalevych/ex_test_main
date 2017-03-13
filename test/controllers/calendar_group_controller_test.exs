defmodule Gt.CalendarGroupControllerTest do
  use Gt.ConnCase

  alias Gt.CalendarGroup
  @valid_attrs %{color: "some content", name: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, calendar_group_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing calendar groups"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, calendar_group_path(conn, :new)
    assert html_response(conn, 200) =~ "New calendar group"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, calendar_group_path(conn, :create), calendar_group: @valid_attrs
    assert redirected_to(conn) == calendar_group_path(conn, :index)
    assert Repo.get_by(CalendarGroup, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, calendar_group_path(conn, :create), calendar_group: @invalid_attrs
    assert html_response(conn, 200) =~ "New calendar group"
  end

  test "shows chosen resource", %{conn: conn} do
    calendar_group = Repo.insert! %CalendarGroup{}
    conn = get conn, calendar_group_path(conn, :show, calendar_group)
    assert html_response(conn, 200) =~ "Show calendar group"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, calendar_group_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    calendar_group = Repo.insert! %CalendarGroup{}
    conn = get conn, calendar_group_path(conn, :edit, calendar_group)
    assert html_response(conn, 200) =~ "Edit calendar group"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    calendar_group = Repo.insert! %CalendarGroup{}
    conn = put conn, calendar_group_path(conn, :update, calendar_group), calendar_group: @valid_attrs
    assert redirected_to(conn) == calendar_group_path(conn, :show, calendar_group)
    assert Repo.get_by(CalendarGroup, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    calendar_group = Repo.insert! %CalendarGroup{}
    conn = put conn, calendar_group_path(conn, :update, calendar_group), calendar_group: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit calendar group"
  end

  test "deletes chosen resource", %{conn: conn} do
    calendar_group = Repo.insert! %CalendarGroup{}
    conn = delete conn, calendar_group_path(conn, :delete, calendar_group)
    assert redirected_to(conn) == calendar_group_path(conn, :index)
    refute Repo.get(CalendarGroup, calendar_group.id)
  end
end
