defmodule Gt.EcbProvider do
  @behaviour Gt.RateProvider

  alias Gt.Repo
  alias Gt.Rate

  def convert(from, to, date, sum) do
    eur_value = to_eur(from, date, sum)
    %Rate{rate: rate} = get_rate(to, date)
    eur_value * rate
  end

  def to_usd(currency, date, sum) do
    convert(currency, "USD", date, sum)
  end

  def get_rate(currency, date) do
    currency = String.upcase(currency)
    case currency do
      "EUR" -> %Rate{rate: 1}
      _ -> Rate.ecb()
           |> Rate.by_currency_date(currency, date)
           |> Repo.one!
    end
  end

  def to_eur(currency, date, sum) do
    %Rate{rate: rate} = get_rate(currency, date)
    sum / rate
  end
end
