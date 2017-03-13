defmodule Gt.DataSourceTest do
  use Gt.ModelCase

  alias Gt.DataSource

  @valid_attrs %{active: true, completed: true, logs: [], name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = DataSource.changeset(%DataSource{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = DataSource.changeset(%DataSource{}, @invalid_attrs)
    refute changeset.valid?
  end
end
