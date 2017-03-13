defmodule Gt.VisitorTest do
  use Gt.ModelCase

  alias Gt.Visitor

  @valid_attrs %{date: %{day: 17, month: 4, year: 2010}, hits: 42, ips: []}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Visitor.changeset(%Visitor{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Visitor.changeset(%Visitor{}, @invalid_attrs)
    refute changeset.valid?
  end
end
