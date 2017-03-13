defmodule Gt.CbrProvider do
  @behaviour Gt.RateProvider

  alias Gt.Repo
  alias Gt.Rate

  def convert(from, to, date, sum) do
    rub_value = to_rub(from, date, sum)
    %Rate{rate: rate} = get_rate(to, date)
    rub_value / rate
  end

  def to_usd(currency, date, sum) do
    convert(currency, "USD", date, sum)
  end

  def get_rate(currency, date) do
    currency = String.upcase(currency)
    case currency do
      "RUB" -> %Rate{rate: 1}
      _ -> Rate.cbr()
           |> Rate.by_currency_date(currency, date)
           |> Repo.one!
    end
  end

  defp to_rub(currency, date, sum) do
    %Rate{rate: rate} = get_rate(currency, date)
    sum * rate
  end
end
