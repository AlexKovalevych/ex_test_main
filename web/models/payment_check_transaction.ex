defmodule Gt.PaymentCheckTransaction do
  use Gt.Web, :model
  use Timex

  schema "payment_check_transactions" do
    field :ps_trans_id, :string
    field :one_gamepay_id, :integer
    field :pguid, :string
    field :sum, :float
    field :currency, :string
    field :fee, :float, default: 0.0
    field :fee_id, :string, virtual: true
    field :fee_currency, :string
    field :date, :naive_datetime
    field :type, :string
    field :account_id, :string
    field :fee_account_id, :string
    field :state, :string
    field :player_purse, :string
    field :comment, :string
    field :source, :map
    field :skipped, :string
    field :lang, :string
    field :report_sum, :float
    field :report_currency, :string

    belongs_to :payment_check, Gt.PaymentCheck
    belongs_to :one_gamepay_transaction, Gt.OneGamepayTransaction

    embeds_many :errors, Gt.PaymentCheckTransactionError

    timestamps()
  end

  @type_in "In"
  @type_out "Out"
  @type_fee "Fee"

  def type(:in), do: @type_in
  def type(:out), do: @type_out
  def type(:fee), do: @type_fee

  def types(), do: [@type_in, @type_out, @type_fee]

  @required_fields ~w(ps_trans_id
                      sum
                      fee
                      date
                      source)a

  @optional_fields ~w(pguid
                      one_gamepay_id
                      currency
                      fee_currency
                      type
                      account_id
                      fee_account_id
                      one_gamepay_transaction_id
                      state
                      player_purse
                      comment
                      skipped
                      lang
                      report_sum
                      report_currency)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    changes = struct |> cast(params, @required_fields ++ @optional_fields)
    if Ecto.Changeset.get_field(changes, :skipped) do
      changes
    else
      changes |> validate_required(@required_fields)
    end
  end

  def by_payment_check(query, id) do
    query |> where([pct], pct.payment_check_id == ^id)
  end

  def duplicate(payment_check_id, trans_id, one_gamepay_id) do
    __MODULE__
    |> by_payment_check(payment_check_id)
    |> where([pct], pct.id != ^trans_id)
    |> where([pct], pct.one_gamepay_id == ^one_gamepay_id)
  end

  def stats(payment_check_id) do
    __MODULE__
    |> by_payment_check(payment_check_id)
    |> join(:left, [pct], ogt in assoc(pct, :one_gamepay_transaction))
    |> select([pct, ogt], %{
      total: count("*"),
      one_gamepay_errors: sum(fragment("CASE WHEN ? @> '[{\"type\": \"1gp\"}]' THEN 1 ELSE 0 END", pct.errors)),
      skipped: sum(fragment("CASE WHEN ? IS NULL THEN 0 ELSE 1 END", pct.skipped)),
      from: min(pct.date),
      to: max(pct.date),
      urls: fragment("array_agg(distinct(?))", ogt.site_url)
    })
  end

  def one_gamepay_errors(query) do
    query |> where([pct], fragment("? @> '[{\"type\": \"1gp\"}]'", pct.errors))
  end

  def one_s_report(query, urls, from, to) do
    from = from |> Timex.to_naive_datetime()
    to = to |> Timex.to_naive_datetime()
    query
    |> select([pct, ogt], %{
      account: pct.account_id,
      site: ogt.site_url,
      type: pct.type,
      date: fragment("date(?)", pct.date),
      currency: pct.currency,
      fee_currency: pct.fee_currency,
      sum: sum(pct.sum),
      fee: sum(pct.fee)
    })
    |> join(:left, [pct], ogt in assoc(pct, :one_gamepay_transaction))
    |> where([pct], fragment("? between ? and ?", pct.date, ^from, ^to))
    |> where([pct, ogt], ogt.site_url in ^urls)
    |> where([pct], fragment("NOT ? @> '[{\"type\": \"1gp\"}]'", pct.errors))
    |> group_by([pct, ogt], [
      pct.account_id,
      ogt.site_url,
      pct.type,
      fragment("date(?)", pct.date),
      pct.currency,
      pct.fee_currency,
    ])
  end

end
