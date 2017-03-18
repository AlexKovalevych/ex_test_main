defmodule Gt.PaymentCheckSourceReportTest do
  use Gt.ModelCase

  alias Gt.PaymentCheckSourceReport

  @valid_attrs %{chargeback: [], currency: "some content", error: "some content", extra_data: %{}, fee_in: [], fee_out: [], filename: "some content", from: %{day: 17, month: 4, year: 2010}, in: [], merchant: "some content", out: [], representment: [], to: %{day: 17, month: 4, year: 2010}}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = PaymentCheckSourceReport.changeset(%PaymentCheckSourceReport{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = PaymentCheckSourceReport.changeset(%PaymentCheckSourceReport{}, @invalid_attrs)
    refute changeset.valid?
  end
end
