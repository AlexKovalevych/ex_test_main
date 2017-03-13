defmodule Gt.ProjectUserBonusTest do
  use Gt.ModelCase

  alias Gt.ProjectUserBonus

  @valid_attrs %{amount: "120.5", currency: "some content", date: %{day: 17, month: 4, year: 2010}, item_id: "some content", type: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = ProjectUserBonus.changeset(%ProjectUserBonus{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = ProjectUserBonus.changeset(%ProjectUserBonus{}, @invalid_attrs)
    refute changeset.valid?
  end
end
