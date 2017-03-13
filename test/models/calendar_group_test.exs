defmodule Gt.CalendarGroupTest do
  use Gt.ModelCase

  alias Gt.CalendarGroup

  @valid_attrs %{color: "some content", name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = CalendarGroup.changeset(%CalendarGroup{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = CalendarGroup.changeset(%CalendarGroup{}, @invalid_attrs)
    refute changeset.valid?
  end
end
