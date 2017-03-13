defmodule Gt.PaymentCheckTransactionTest do
  use Gt.ModelCase

  alias Gt.PaymentCheckTransaction

  @valid_attrs %{account_id: "some content", currency: "some content", date: %{day: 17, month: 4, year: 2010}, errors: [], one_gamepay_id: "some content", player_purse: "some content", ps_trans_id: "some content", source: %{}, state: "some content", sum: "120.5", type: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = PaymentCheckTransaction.changeset(%PaymentCheckTransaction{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PaymentCheckTransaction.changeset(%PaymentCheckTransaction{}, @invalid_attrs)
    refute changeset.valid?
  end
end
