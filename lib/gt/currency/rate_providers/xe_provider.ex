defmodule Gt.XeProvider do
  @behaviour Gt.RateProvider

  alias Gt.Repo
  alias Gt.Rate

  def convert(from, to, date, sum) do
    usd_value = to_usd(from, date, sum)
    %Rate{rate: rate} = get_rate(to, date)
    usd_value * rate
  end

  def to_usd(currency, date, sum) do
    %Rate{rate: rate} = get_rate(currency, date)
    sum / rate
  end

  def get_rate(currency, date) do
    currency = String.upcase(currency)
    case currency do
      "USD" -> %Rate{rate: 1}
      _ -> Rate.xe()
           |> Rate.by_currency_date(currency, date)
           |> Repo.one!
    end
  end
end
