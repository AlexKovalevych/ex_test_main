defmodule Gt.DataSource.OneGamepay do
  alias Gt.{
    DataSourceRegistry,
    OneGamepayTransaction,
    Project,
    Repo
  }
  alias Mailroom.IMAP
  require Logger

  def process_api(data_source) do
    ssl = if data_source.encryption, do: true, else: false
    Logger.info("Connecting to mailbox #{data_source.mailbox}")
    {:ok, client} = IMAP.connect(data_source.host, data_source.mailbox, data_source.password, port: data_source.port, ssl: ssl)
    Logger.info("Connected to mailbox #{data_source.mailbox}")
    {:ok, msg_ids} = client
    |> IMAP.select(:inbox)
    |> IMAP.search("UNSEEN", :envelope)

    total_files = Enum.count(msg_ids)
    Logger.info("Processing #{total_files} emails")
    msg_ids
    |> Enum.with_index
    |> Enum.each(fn {msg_id, index} ->
      {:ok, [{_, %{rfc822_text: body}}]} = IMAP.fetch(client, msg_id, [:rfc822_text])
      IMAP.remove_flags(client, msg_id, :seen) # No unseen flag, just /Seen which needs to be removed

      [key | body] = body
      |> String.split("\r\n")
      |> Enum.filter(fn line -> line != "" end)

      [_ | ["Content-Transfer-Encoding: " <> encoding | text_plain]] = body
      |> Enum.chunk_by(fn line -> line != key end)
      |> Enum.filter(fn part -> part != [key] end)
      |> List.first

      if encoding != "base64" do
        message = "Unexpected encoding #{encoding} in email #{msg_id}"
        Logger.error(message)
        exit(message)
      else
        %{"url" => link} = Regex.named_captures(~r/(?<url>http[^\s]*)/, text_plain |> Enum.join("") |> Base.decode64!)
        Logger.info("Loading transactions from #{link}")
        response = HTTPotion.get(link)

        separator = get_separator(data_source)
        double_qoute = get_double_qoute(data_source)

        lines = response.body |> String.split("\n") |> Enum.filter(fn line -> line != "" end)
        count = lines |> Enum.count
        # Minus header line
        count = count - 1

        DataSourceRegistry.save(data_source.id, :total, total_files * count)
        DataSourceRegistry.save(data_source.id, :processed, index * count)

        lines
        |> CSV.decode(headers: true, separator: separator, double_qoute: double_qoute)
        |> ParallelStream.each(fn row -> process_row(row, data_source) end)
        |> Enum.reduce(0, fn _, acc -> acc + 1 end)
      end
      IMAP.add_flags(client, msg_id, :seen)
    end)

    client
    |> IMAP.expunge
    |> IMAP.logout
  end

  def process_file(data_source, {filename, index}, total_files) do
    path = Gt.Uploaders.DataSource.local_path(data_source.id, filename)
    separator = get_separator(data_source)
    double_qoute = get_double_qoute(data_source)

    count = path
    |> File.stream!()
    |> Enum.count
    # Minus header line
    count = count - 1
    Logger.info("Processing #{count} transactions from file: #{filename}")

    DataSourceRegistry.save(data_source.id, :total, total_files * count)
    DataSourceRegistry.save(data_source.id, :processed, index * count)

    path
    |> File.stream!()
    |> CSV.decode(headers: true, separator: separator, double_qoute: double_qoute)
    |> ParallelStream.each(fn row -> process_row(row, data_source) end)
    |> Enum.reduce(0, fn _, acc -> acc + 1 end)
  end

  defp process_row(row, data_source) do
    ps_trans_id = row["Acquirer transaction ID"]
    ps_trans_id = if ps_trans_id, do: Regex.replace(~r/^\D*/, ps_trans_id, ""), else: nil
    trans_id = row["Transaction ID"]
    trans_id = if trans_id, do: Regex.replace(~r/^T/, trans_id, ""), else: nil
    merchant = Map.get(row, "Merchant name", data_source.name) |> String.downcase
    date = Map.get(row, "Date of transaction", row["Date and time of completion of transaction"])
           |> parse_date()
    time = Map.get(row, "Time of transaction", row["Time of completion of transaction"])
           |> parse_time()
    date = if time, do: Timex.set(date, hour: time.hour, minute: time.minute, second: time.second), else: date

    sum = Map.get(row, "Transaction amount", row["Amount"])
    currency = Map.get(row, "Transaction currency", row["Currency"])
    url = row["Site URL"]
    project = Project
              |> Project.by_url(url)
              |> Repo.one
    channel_sum = cond do
      !row["Channel amount"] -> nil
      {channel_sum, _} = Float.parse(row["Channel amount"]) -> channel_sum * 100 |> round
      true -> nil
    end
    if project do
      %OneGamepayTransaction{}
      |> OneGamepayTransaction.changeset(%{
        trans_id: trans_id,
        ps_trans_id: ps_trans_id,
        project_trans_id: row["Order"],
        ps_name: row["Payment instrument type"],
        payment_instrument_name: row["Payment instrument ID"],
        date: date,
        sum: sum,
        currency: currency,
        site_url: url,
        processor_code_descruption: row["Processor code description"],
        status: row["Transaction status"],
        rate: row["Currency Rate"],
        channel_sum: channel_sum,
        channel_currency: row["Channel currency"],
        transaction_type: row["Transaction type"],
        merchant: merchant,
        project_id: project.id
      })
      |> Repo.insert!(on_conflict: :nothing)
    else
      Logger.error("Can't find project for url #{url}")
    end
    DataSourceRegistry.increment(data_source.id, :processed)
  end

  defp get_separator(data_source) do
    case data_source.separator do
      "comma" -> ?,
      "tab" -> ?\t
      "colon" -> ?:
      "pipe" -> ?|
      "space" -> ?\s
      "semicolon" -> ?;
      _ -> ?,
    end
  end

  defp get_double_qoute(data_source) do
    case data_source.separator do
      "double_qoute" -> ?"
      "single_qoute" -> ?'
      _ -> ?"
    end
  end

  defp parse_date(nil), do: nil

  defp parse_date(date) do
    case String.length(date) do
      10 -> Timex.parse!(date, "{ISOdate}")
      19 -> Timex.parse!(date, "{ISOdate} {ISOtime}")
      25 -> Timex.parse!(date, "{ISOdate} {ISOtime}{Z:}")
    end
  end

  defp parse_time(nil), do: nil

  defp parse_time(time) do
    case String.length(time) do
      8 -> Timex.parse!(time, "{ISOtime}")
    end
  end

end
