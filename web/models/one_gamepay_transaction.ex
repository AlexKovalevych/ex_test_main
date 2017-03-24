defmodule Gt.OneGamepayTransaction do
  use Gt.Web, :model

  schema "one_gamepay_transactions" do
    field :trans_id, :integer
    field :ps_trans_id, :string
    field :project_trans_id, :string
    field :ps_name, :string
    field :payment_instrument_name, :string
    field :status, :string
    field :date, :naive_datetime
    field :sum, :integer
    field :currency, :string
    field :channel_sum, :integer
    field :channel_currency, :string
    field :site_url, :string
    field :processor_code_description, :string
    field :rate, :float
    field :transaction_type, :string
    field :merchant, :string

    belongs_to :project, Gt.Project

    timestamps()
  end

  @type_in "purchase"
  @type_out "payout"

  def type(:in), do: @type_in
  def type(:out), do: @type_out

  @required_fields ~w(trans_id
                      project_trans_id
                      ps_name
                      status
                      date
                      sum
                      channel_sum
                      channel_currency
                      site_url
                      transaction_type
                      merchant)a

  @optional_fields ~w(ps_trans_id
                      processor_code_description
                      payment_instrument_name
                      currency
                      rate
                      project_id
                    )a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def by_payment_check_transaction(payment_check, transaction) do
    query = __MODULE__
    query = if !is_nil(transaction.one_gamepay_id) do
      query |> where([ogt], ogt.trans_id == ^transaction.one_gamepay_id)
    else
      query
    end

    ps = payment_check.ps["one_gamepay"]["payment_system"]
    query = if ps do
      ps_value = "(#{String.replace(ps, ",", "|")})"
      query |> or_where([ogt], ogt.ps_trans_id == ^transaction.ps_trans_id and
              fragment("? ~* ?", ogt.ps_name, ^ps_value))
    else
      query
    end

    if transaction.pguid do
      query |> or_where([ogt], ogt.project_trans_id == ^transaction.pguid)
    else
      query
    end
  end

end
