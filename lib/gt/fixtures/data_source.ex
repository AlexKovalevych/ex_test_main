defmodule Gt.Fixtures.DataSource do
  alias Gt.DataSource
  alias Gt.Repo
  use Timex

  def run do
    now = Timex.today

    %DataSource{type: "rates"}
    |> DataSource.changeset(%{
      name: "xe rates",
      host: "http://www.xe.com/currencytables/",
      subtype: "xe",
      start_at: ~D[2017-02-01],
      end_at: now,
      interval: 720,
    })
    |> Repo.insert!

    %DataSource{type: "rates"}
    |> DataSource.changeset(%{
      name: "cbr rates",
      host: "http://www.cbr.ru/scripts/XML_daily.asp",
      subtype: "cbr",
      start_at: ~D[2017-02-01],
      end_at: now,
      interval: 720,
    })
    |> Repo.insert!

    %DataSource{type: "rates"}
    |> DataSource.changeset(%{
      name: "ecb rates",
      host: "https://sdw-wsrest.ecb.europa.eu/service/data/EXR/D..EUR.SP00.A",
      subtype: "ecb",
      start_at: ~D[2017-02-01],
      end_at: now,
      interval: 720,
    })
    |> Repo.insert!

  end

end
