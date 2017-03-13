defmodule Gt.CalendarEventTest do
  use Gt.ModelCase

  alias Gt.CalendarEvent

  @valid_attrs %{description: "some content", end_at: %{day: 17, month: 4, year: 2010}, start_at: %{day: 17, month: 4, year: 2010}}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = CalendarEvent.changeset(%CalendarEvent{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = CalendarEvent.changeset(%CalendarEvent{}, @invalid_attrs)
    refute changeset.valid?
  end
end
