defmodule Gt.CacheControllerTest do
  use Gt.ConnCase

  alias Gt.Cache
  @valid_attrs %{end: "some content", logs: %{}, processed: 42, projects: %{}, start: "some content", total: 42}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, cache_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing caches"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, cache_path(conn, :new)
    assert html_response(conn, 200) =~ "New cache"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, cache_path(conn, :create), cache: @valid_attrs
    assert redirected_to(conn) == cache_path(conn, :index)
    assert Repo.get_by(Cache, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, cache_path(conn, :create), cache: @invalid_attrs
    assert html_response(conn, 200) =~ "New cache"
  end

  test "shows chosen resource", %{conn: conn} do
    cache = Repo.insert! %Cache{}
    conn = get conn, cache_path(conn, :show, cache)
    assert html_response(conn, 200) =~ "Show cache"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, cache_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    cache = Repo.insert! %Cache{}
    conn = get conn, cache_path(conn, :edit, cache)
    assert html_response(conn, 200) =~ "Edit cache"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    cache = Repo.insert! %Cache{}
    conn = put conn, cache_path(conn, :update, cache), cache: @valid_attrs
    assert redirected_to(conn) == cache_path(conn, :show, cache)
    assert Repo.get_by(Cache, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    cache = Repo.insert! %Cache{}
    conn = put conn, cache_path(conn, :update, cache), cache: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit cache"
  end

  test "deletes chosen resource", %{conn: conn} do
    cache = Repo.insert! %Cache{}
    conn = delete conn, cache_path(conn, :delete, cache)
    assert redirected_to(conn) == cache_path(conn, :index)
    refute Repo.get(Cache, cache.id)
  end
end
