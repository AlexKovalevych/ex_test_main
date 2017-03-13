defmodule Gt.PokerBonusTest do
  use Gt.ModelCase

  alias Gt.PokerBonus

  @valid_attrs %{amount: "120.5", currency: "some content", date: %{day: 17, month: 4, year: 2010}, type: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = PokerBonus.changeset(%PokerBonus{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PokerBonus.changeset(%PokerBonus{}, @invalid_attrs)
    refute changeset.valid?
  end
end
