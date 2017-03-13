defmodule Gt.OneGamepayTransactionTest do
  use Gt.ModelCase

  alias Gt.OneGamepayTransaction

  @valid_attrs %{channel_currency: "some content", channel_sum: 42, date: %{day: 17, month: 4, year: 2010}, merchant: "some content", payment_instrument_name: "some content", processor_code_description: "some content", project_trans_id: "some content", ps_name: "some content", ps_trans_id: "some content", rate: "120.5", site_url: "some content", status: "some content", sum: 42, transaction_type: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = OneGamepayTransaction.changeset(%OneGamepayTransaction{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = OneGamepayTransaction.changeset(%OneGamepayTransaction{}, @invalid_attrs)
    refute changeset.valid?
  end
end
