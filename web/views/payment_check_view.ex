defmodule Gt.PaymentCheckView do
  use Gt.Web, :view
  alias Gt.PaymentCheckTransactionError
  alias Gt.PaymentCheckTransaction
  alias Gt.Report.PaymentCheckOneS
  alias Gt.Repo
  require Ecto.Query
  import Gt.Gettext

  def render("1c.csv", %{payment_check: payment_check, one_s: %PaymentCheckOneS{urls: urls, from: from, to: to}}) do
    headers = ~w(Acc Date Site Type Curr Sum)
    rows = PaymentCheckTransaction
    |> PaymentCheckTransaction.by_payment_check(payment_check.id)
    |> PaymentCheckTransaction.one_s_report(urls, from, to)
    |> Repo.all
    |> Enum.map(fn data ->
      [one_s_account(payment_check, data),
       Gt.Date.format(Date.from_erl!(data.date), :date),
       data.site,
       data.type,
       data.currency,
       one_s_sum(data)
     ]
    end)

    [headers | rows]
    |> CSV.encode
    |> Enum.to_list
  end

  def render("1gp.csv", %{payment_check: payment_check}) do
    headers = [
      dgettext("payment_checks", "ps_id"),
      dgettext("payment_checks", "1gp_id"),
      dgettext("payment_checks", "account_id"),
      dgettext("payment_checks", "date"),
      dgettext("payment_checks", "site"),
      dgettext("payment_checks", "type"),
      dgettext("payment_checks", "currency"),
      dgettext("payment_checks", "sum"),
      dgettext("payment_checks", "comment"),
      dgettext("payment_checks", "1gp_sum"),
      dgettext("payment_checks", "1gp_currency"),
      dgettext("payment_checks", "1gp_channel_currency"),
      dgettext("payment_checks", "1gp_channel_sum"),
      dgettext("payment_checks", "errors"),
    ]
    rows = PaymentCheckTransaction
    |> PaymentCheckTransaction.by_payment_check(payment_check.id)
    |> PaymentCheckTransaction.one_gamepay_errors()
    |> Ecto.Query.preload(:one_gamepay_transaction)
    |> Repo.all
    |> Enum.map(&Gt.Report.PaymentCheck.one_gamepay_error/1)

    [headers | rows]
    |> CSV.encode
    |> Enum.to_list
  end

  def is_started(payment_check) do
    Gt.PaymentCheck.is_started(payment_check)
  end

  def translate_1gp_error(%{message: message}) do
    [
      {PaymentCheckTransactionError.message(:not_found), dgettext("payment_checks", "not_found")},
      {PaymentCheckTransactionError.message(:duplicate), dgettext("payment_checks", "duplicate")},
      {PaymentCheckTransactionError.message(:invalid_sum), dgettext("payment_checks", "invalid_sum")},
      {PaymentCheckTransactionError.message(:invalid_currency), dgettext("payment_checks", "invalid_currency")},
      {PaymentCheckTransactionError.message(:invalid_date), dgettext("payment_checks", "invalid_date")},
    ]
    |> Map.new
    |> Map.get(message, nil)
  end

  defp one_s_account(payment_check, data) do
    fee_type = PaymentCheckTransaction.type(:fee)
    case data.type do
      ^fee_type -> Map.get(data, :account, payment_check.ps["fee"]["default_account_id"])
      _ -> data.account
    end
  end

  defp one_s_sum(data) do
    fee_type = PaymentCheckTransaction.type(:fee)
    sum = case data.type do
      ^fee_type -> data.fee
      _ -> data.sum
    end
    (sum / 1) |> abs |> Float.round(2)
  end
end
