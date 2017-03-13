defmodule Gt.CalendarTypeControllerTest do
  use Gt.ConnCase

  alias Gt.CalendarType
  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, calendar_type_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing calendar types"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, calendar_type_path(conn, :new)
    assert html_response(conn, 200) =~ "New calendar type"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, calendar_type_path(conn, :create), calendar_type: @valid_attrs
    assert redirected_to(conn) == calendar_type_path(conn, :index)
    assert Repo.get_by(CalendarType, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, calendar_type_path(conn, :create), calendar_type: @invalid_attrs
    assert html_response(conn, 200) =~ "New calendar type"
  end

  test "shows chosen resource", %{conn: conn} do
    calendar_type = Repo.insert! %CalendarType{}
    conn = get conn, calendar_type_path(conn, :show, calendar_type)
    assert html_response(conn, 200) =~ "Show calendar type"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, calendar_type_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    calendar_type = Repo.insert! %CalendarType{}
    conn = get conn, calendar_type_path(conn, :edit, calendar_type)
    assert html_response(conn, 200) =~ "Edit calendar type"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    calendar_type = Repo.insert! %CalendarType{}
    conn = put conn, calendar_type_path(conn, :update, calendar_type), calendar_type: @valid_attrs
    assert redirected_to(conn) == calendar_type_path(conn, :show, calendar_type)
    assert Repo.get_by(CalendarType, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    calendar_type = Repo.insert! %CalendarType{}
    conn = put conn, calendar_type_path(conn, :update, calendar_type), calendar_type: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit calendar type"
  end

  test "deletes chosen resource", %{conn: conn} do
    calendar_type = Repo.insert! %CalendarType{}
    conn = delete conn, calendar_type_path(conn, :delete, calendar_type)
    assert redirected_to(conn) == calendar_type_path(conn, :index)
    refute Repo.get(CalendarType, calendar_type.id)
  end
end
