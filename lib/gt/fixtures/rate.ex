defmodule Gt.Fixtures.Rate do
  alias Gt.Rate
  alias Gt.Repo
  require Logger
  use Timex

  def run do
    create_rates("xe_rates.csv") |> Enum.each(fn rates -> Repo.insert_all({"xe_rates", Rate}, rates) end)
    create_rates("cbr_rates.csv") |> Enum.each(fn rates -> Repo.insert_all({"cbr_rates", Rate}, rates) end)
    create_rates("ecb_rates.csv") |> Enum.each(fn rates -> Repo.insert_all({"ecb_rates", Rate}, rates) end)
  end

  defp create_rates(filename) do
    File.stream!(Path.join(__DIR__, filename))
    |> CSV.decode()
    |> Enum.map(fn [date, currency, rate] ->
      date = Timex.parse!(date, "{ISOdate}") |> Timex.to_date
      {rate, _} = Float.parse(rate)
      %{date: date, currency: currency, rate: rate}
    end)
    |> Enum.chunk(10000, 10000, [])
  end

end
