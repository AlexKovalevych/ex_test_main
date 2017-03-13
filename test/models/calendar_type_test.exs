defmodule Gt.CalendarTypeTest do
  use Gt.ModelCase

  alias Gt.CalendarType

  @valid_attrs %{name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = CalendarType.changeset(%CalendarType{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = CalendarType.changeset(%CalendarType{}, @invalid_attrs)
    refute changeset.valid?
  end
end
