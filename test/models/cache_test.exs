defmodule Gt.CacheTest do
  use Gt.ModelCase

  alias Gt.Cache

  @valid_attrs %{end: "some content", logs: %{}, processed: 42, projects: %{}, start: "some content", total: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Cache.changeset(%Cache{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Cache.changeset(%Cache{}, @invalid_attrs)
    refute changeset.valid?
  end
end
