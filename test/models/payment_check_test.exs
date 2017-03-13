defmodule Gt.PaymentCheckTest do
  use Gt.ModelCase

  alias Gt.PaymentCheck

  @valid_attrs %{active: true, completed: true, files: [], processed: 42, total: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = PaymentCheck.changeset(%PaymentCheck{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PaymentCheck.changeset(%PaymentCheck{}, @invalid_attrs)
    refute changeset.valid?
  end
end
