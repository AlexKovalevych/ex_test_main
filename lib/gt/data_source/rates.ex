defmodule Gt.DataSource.Rates do
  alias Gt.DataSourceRegistry
  alias Gt.Repo
  alias Gt.Rate
  alias Gt.DataSource
  import SweetXml
  use Timex
  require Logger

  def process_file(%DataSource{subtype: "xe"} = data_source, filename) do
    Logger.info("Parsing xe rates from file #{filename}")
    Gt.Uploaders.DataSource.local_path(data_source.id, filename)
    |> File.stream!()
    |> stream_tags([:currency])
    |> ParallelStream.each(fn {_, doc} ->
      %{currency: currency, rate: rate, date: date} = xpath(doc, ~x".",
                                                            currency: ~x"@symbol"s,
                                                            rate: ~x"@rate",
                                                            date: ~x"@updated")
      date = Timex.parse(date, "{ISOdate} {ISOtime}")
      save_xe_rate(currency, date, rate)
    end)
    |> Enum.to_list
    DataSourceRegistry.save(data_source.id, :processed, 1)
  end

  def process_file(%DataSource{subtype: "cbr"} = data_source, filename) do
    Logger.info("Parsing xe rates from file #{filename}")
    stream = Gt.Uploaders.DataSource.local_path(data_source.id, filename)
    |> File.stream!()
    |> Stream.map(fn line ->
      line = String.replace(line, "windows-1251", "utf-8")
      :iconv.convert("windows-1251", "utf-8", line)
    end)

    [date] = stream
    |> stream_tags(:ValCurs)
    |> Stream.map(fn {_, doc} ->
        xpath(doc, ~x"@Date")
    end)
    |> Enum.to_list
    date = Timex.parse(date, "%d.%m.%Y", :strftime)
    # if date is friday, set same rates for the weekends
    dates = if Timex.format!(date, "{WDshort}") == "Fri" do
      [date, Timex.shift(date, days: 1), Timex.shift(date, days: 2)]
    else
      [date]
    end

    stream
    |> stream_tags(:Valute)
    |> Stream.each(fn {_, doc} ->
      %{currency: currency, rate: rate} = xpath(doc, ~x".", currency: ~x"CharCode/text()"s, rate: ~x"Value/text()"s)
      Enum.each(dates, fn date ->
        save_xe_rate(currency, date, String.replace(rate, ",", ".") |> String.to_float)
      end)
    end)
    |> Enum.reduce(0, fn _, acc -> acc + 1 end)
    DataSourceRegistry.save(data_source.id, :processed, 1)
  end

  def process_file(%DataSource{subtype: "ecb"} = data_source, filename) do
    Logger.info("Parsing xe rates from file #{filename}")
    Gt.Uploaders.DataSource.local_path(data_source.id, filename)
    |> File.stream!()
    |> stream_tags([:currency])
    |> Stream.each(fn {_, doc} ->
      %{currency: currency, rate: rate, date: date} = xpath(doc, ~x".",
                                                            currency: ~x"@symbol"s,
                                                            rate: ~x"@rate",
                                                            date: ~x"@updated")
      date = Timex.parse(date, "{ISOdate} {ISOtime}")
      Logger.info("Saving ecb rate #{currency} for date #{Timex.format!(date, "{ISOdate}")}")
      save_xe_rate(currency, date, rate)
    end)
    |> Enum.reduce(0, fn _, acc -> acc + 1 end)
    DataSourceRegistry.save(data_source.id, :processed, 1)
  end

  def process_api(%DataSource{subtype: "xe", start_at: start_at, end_at: end_at} = data_source) do
    diff = Timex.diff(end_at, start_at, :days)
    dates = Interval.new(from: start_at, until: [days: diff], step: [days: 1], right_open: false)
    DataSourceRegistry.save(data_source.id, :total, Enum.count(dates))
    dates
    |> Enum.each(fn date ->
      query = %{from: "USD", date: Timex.format!(date, "{ISOdate}")}
      Logger.info("Loading rates from #{data_source.host} with parameters: #{inspect(query)}")
      response = HTTPotion.get(data_source.host, query: query)
      case HTTPotion.Response.success?(response) do
        true ->
          response.body
          |> Floki.find("#historicalRateTbl tbody tr")
          |> Enum.map(fn row ->
            currency = Floki.find(row, "td:first-child") |> Floki.text()
            rate = row
                   |> Floki.find("td.historicalRateTable-rateHeader")
                   |> List.first()
                   |> Floki.text()
                   |> String.to_float()
            save_xe_rate(currency, date, rate)
          end)
        false ->
          if Map.has_keys?(response, :status_code) && Map.has_keys?(response, :body) do
            Logger.error("Can't get xe rate for date #{date}; code: #{response.status_code}; body: #{response.body}")
          else
            Logger.error("Can't get xe rate for date #{date}; #{response.message}")
          end
      end
      DataSourceRegistry.increment(data_source.id, :processed)
    end)
  end

  def process_api(%DataSource{subtype: "cbr", start_at: start_at, end_at: end_at} = data_source) do
    diff = Timex.diff(end_at, start_at, :days)
    dates = Interval.new(from: start_at, until: [days: diff], step: [days: 1], right_open: false)
    DataSourceRegistry.save(data_source.id, :total, Enum.count(dates))
    dates
    |> Enum.each(fn date ->
      query = %{date_req: Timex.format!(date, "%d/%m/%Y", :strftime)}
      Logger.info("Loading rates from #{data_source.host} with parameters: #{inspect(query)}")
      response = HTTPotion.get(data_source.host, query: query)
      case HTTPotion.Response.success?(response) do
        true ->
          xml = response.body |> String.replace("windows-1251", "utf-8")
          xml = :iconv.convert("windows-1251", "utf-8", xml)

          # if date is friday, set same rates for the weekends
          dates = if Timex.format!(date, "{WDshort}") == "Fri" do
            [date, Timex.shift(date, days: 1), Timex.shift(date, days: 2)]
          else
            [date]
          end

          xml
          |> xpath(~x"Valute"l, currency: ~x"CharCode/text()"s, rate: ~x"Value/text()"s)
          |> Enum.each(fn %{currency: currency, rate: rate} ->
            Enum.each(dates, fn date ->
              save_cbr_rate(currency, date, String.replace(rate, ",", ".") |> String.to_float)
            end)
          end)
          false ->
          Logger.error("Can't get cbr rate for date #{Timex.format!(date, "{ISOdate}")}; code: #{response.status_code}; body: #{response.body}")
      end
      DataSourceRegistry.increment(data_source.id, :processed)
    end)
  end

  def process_api(%DataSource{subtype: "ecb", start_at: start_at, end_at: end_at} = data_source) do
    query = %{
      startPeriod: Timex.format!(start_at, "{ISOdate}"),
       endPeriod: Timex.format!(end_at, "{ISOdate}")
    }
    Logger.info("Loading rates from #{data_source.host} with parameters: #{inspect(query)}")
    response = HTTPotion.get(data_source.host, query: query)
    case HTTPotion.Response.success?(response) do
      true ->
        xml = response.body |> xpath(~x"//message:GenericData/message:DataSet/generic:Series"l)
        DataSourceRegistry.save(data_source.id, :total, Enum.count(xml))
        Enum.each(xml, fn xml ->
          [currency] = xml
          |> xpath(~x"generic:SeriesKey/generic:Value"l)
          |> Enum.filter_map(
            fn xml -> xpath(xml, ~x"@id"s) == "CURRENCY" end,
            fn xml -> xpath(xml, ~x"@value"s) end
          )
          xpath(xml, ~x"generic:Obs"l, date: ~x"generic:ObsDimension/@value"s, rate: ~x"generic:ObsValue/@value"f)
          |> Enum.each(fn %{date: date, rate: rate} ->
            date = Timex.parse!(date, "{ISOdate}")
            # if date is friday, set same rates for the weekends
            dates = if Timex.format!(date, "{WDshort}") == "Fri" do
              [date, Timex.shift(date, days: 1), Timex.shift(date, days: 2)]
            else
              [date]
            end
            Enum.each(dates, fn date ->
              save_ecb_rate(currency, date, rate)
            end)
          end)
          DataSourceRegistry.increment(data_source.id, :processed)
        end)
      false ->
        from = Timex.format!(start_at, "{ISOdate}")
        to = Timex.format!(end_at, "{ISOdate}")
        Logger.error("Can't get ecb rate for period: #{from} : #{to}; code: #{response.status_code}; body: #{response.body}")
    end
  end

  defp save_xe_rate(currency, date, rate) do
    Logger.info("Saving xe rate #{currency} for date #{Timex.format!(date, "{ISOdate}")}")
    xe_rate = Rate.xe() |> Rate.by_currency_date(currency, date) |> Repo.one
    if xe_rate do
      Rate.changeset(xe_rate, %{rate: rate}) |> Repo.update!
    else
      Rate.changeset(%Rate{} |> Ecto.put_meta(source: "xe_rates"), %{
        currency: currency,
        rate: rate,
        date: date
      })
      |> Repo.insert!
    end
  end

  defp save_cbr_rate(currency, date, rate) do
    Logger.info("Saving cbr rate #{currency} date #{Timex.format!(date, "{ISOdate}")}")
    cbr_rate = Rate.cbr() |> Rate.by_currency_date(currency, date) |> Repo.one
    if cbr_rate do
      Rate.changeset(cbr_rate, %{rate: rate}) |> Repo.update!
    else
      Rate.changeset(%Rate{} |> Ecto.put_meta(source: "cbr_rates"), %{
        currency: currency,
        rate: rate,
        date: date
      })
      |> Repo.insert!
    end
  end

  defp save_ecb_rate(currency, date, rate) do
    Logger.info("Saving xe rate #{currency} for date #{Timex.format!(date, "{ISOdate}")}")
    ecb_rate = Rate.ecb() |> Rate.by_currency_date(currency, date) |> Repo.one
    if ecb_rate do
      Rate.changeset(ecb_rate, %{rate: rate}) |> Repo.update!
    else
      Rate.changeset(%Rate{} |> Ecto.put_meta(source: "ecb_rates"), %{
        currency: currency,
        rate: rate,
        date: date
      })
      |> Repo.insert!
    end
  end

end
