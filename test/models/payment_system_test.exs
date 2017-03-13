defmodule Gt.PaymentSystemTest do
  use Gt.ModelCase

  alias Gt.PaymentSystem

  @valid_attrs %{name: "some content", script: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = PaymentSystem.changeset(%PaymentSystem{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PaymentSystem.changeset(%PaymentSystem{}, @invalid_attrs)
    refute changeset.valid?
  end
end
