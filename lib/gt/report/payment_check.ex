defmodule Gt.Report.PaymentCheckOneS do
  use Gt.Web, :model

  schema "abstract(one_s_report)" do
    field :from, :date
    field :to, :date
    field :urls, {:array, :string}, default: []
  end

  @required_fields ~w(from to urls)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end

defmodule Gt.Report.PaymentCheck do
  defstruct stats: nil, tab: 1, one_gamepay_errors: nil, one_gamepay_page: 1, one_s_changeset: nil

  alias Gt.PaymentCheckTransaction
  alias Gt.Repo

  @one_gamepay_fields ~w(ps_trans_id
                         one_gamepay_id
                         account_id
                         date
                         site
                         type
                         currency
                         sum
                         comment
                         one_gp_sum
                         one_gp_currency
                         one_gp_channel_currency
                         one_gp_channel_sum
                         errors)a

  def one_gamepay_fields(), do: @one_gamepay_fields

  def one_gamepay_errors(payment_check, params) do
    PaymentCheckTransaction
    |> PaymentCheckTransaction.by_payment_check(payment_check.id)
    |> PaymentCheckTransaction.one_gamepay_errors()
    |> Repo.paginate(params)
    |> Enum.map(fn transaction ->
       Enum.zip(@one_gamepay_fields, one_gamepay_error(transaction))
    end)
  end

  def one_gamepay_error(transaction) do
    [site, one_gp_sum, one_gp_currency, one_gp_channel_currency, one_gp_channel_sum] = if !transaction.one_gamepay_transaction do
      Stream.cycle([""]) |> Enum.take(5)
    else
      [
        transaction.one_gamepay_transaction.site_url,
        trunc(transaction.one_gamepay_transaction.sum),
        transaction.one_gamepay_transaction.currency,
        transaction.one_gamepay_transaction.channel_currency,
        trunc(transaction.one_gamepay_transaction.channel_sum),
      ]
    end

    errors = transaction.errors
             |> Enum.filter(fn error ->
               case error do
                 %{type: "1gp"} -> true
                 _ -> false
               end
             end)
             |> Enum.map(&Gt.PaymentCheckView.translate_1gp_error/1)
             |> Enum.join(", ")

    [
      transaction.ps_trans_id,
      transaction.one_gamepay_id,
      transaction.account_id,
      transaction.date |> Gt.Date.format(:datetime),
      site,
      transaction.type,
      transaction.currency,
      get_sum(transaction.sum, true),
      transaction.comment,
      get_sum(one_gp_sum),
      one_gp_currency,
      one_gp_channel_currency,
      get_sum(one_gp_channel_sum),
      errors
    ]
  end

  defp get_sum(sum, abs \\ false) when is_number(sum) do
    val = if abs, do: abs(sum), else: sum
    Money.new(round(val * 100)) |> Money.to_string(symbol: false, fractional_unit: true)
  end

  defp get_sum(sum, _), do: sum
end
