defmodule Gt.CalendarEventControllerTest do
  use Gt.ConnCase

  alias Gt.CalendarEvent
  @valid_attrs %{description: "some content", end_at: %{day: 17, month: 4, year: 2010}, start_at: %{day: 17, month: 4, year: 2010}}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, calendar_event_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing calendar events"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, calendar_event_path(conn, :new)
    assert html_response(conn, 200) =~ "New calendar event"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, calendar_event_path(conn, :create), calendar_event: @valid_attrs
    assert redirected_to(conn) == calendar_event_path(conn, :index)
    assert Repo.get_by(CalendarEvent, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, calendar_event_path(conn, :create), calendar_event: @invalid_attrs
    assert html_response(conn, 200) =~ "New calendar event"
  end

  test "shows chosen resource", %{conn: conn} do
    calendar_event = Repo.insert! %CalendarEvent{}
    conn = get conn, calendar_event_path(conn, :show, calendar_event)
    assert html_response(conn, 200) =~ "Show calendar event"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, calendar_event_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    calendar_event = Repo.insert! %CalendarEvent{}
    conn = get conn, calendar_event_path(conn, :edit, calendar_event)
    assert html_response(conn, 200) =~ "Edit calendar event"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    calendar_event = Repo.insert! %CalendarEvent{}
    conn = put conn, calendar_event_path(conn, :update, calendar_event), calendar_event: @valid_attrs
    assert redirected_to(conn) == calendar_event_path(conn, :show, calendar_event)
    assert Repo.get_by(CalendarEvent, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    calendar_event = Repo.insert! %CalendarEvent{}
    conn = put conn, calendar_event_path(conn, :update, calendar_event), calendar_event: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit calendar event"
  end

  test "deletes chosen resource", %{conn: conn} do
    calendar_event = Repo.insert! %CalendarEvent{}
    conn = delete conn, calendar_event_path(conn, :delete, calendar_event)
    assert redirected_to(conn) == calendar_event_path(conn, :index)
    refute Repo.get(CalendarEvent, calendar_event.id)
  end
end
