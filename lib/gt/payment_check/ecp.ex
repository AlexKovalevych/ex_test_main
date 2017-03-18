defmodule Gt.PaymentCheck.Ecp do
  @behaviour Gt.PaymentCheck.Processor

  alias Gt.PaymentCheck.Processor
  alias Gt.OneGamepayTransaction
  alias Gt.PaymentCheck
  alias Gt.PaymentCheckRegistry
  alias Gt.PaymentCheckTransaction
  alias Gt.PaymentCheckTransactionError
  alias Gt.PaymentCheckSourceReport
  alias Gt.PaymentCheckSourceValue
  alias Gt.Repo
  require Logger

  def run(payment_check) do
    total_files = Enum.count(payment_check.files)
    Logger.info("Processing #{total_files} files")
    PaymentCheckRegistry.save(payment_check.id, :total, 0)
    total_report_sources = payment_check.files
    |> Enum.with_index
    |> Enum.map(fn {filename, index} ->
      Logger.info("Processing #{filename} file")
      process_report_file(payment_check, {Gt.Uploaders.PaymentCheck.local_path(payment_check.id, filename), index}, total_files)
    end)
    IO.inspect(total_report_sources)
  end

  def process_report_file(payment_check, {path, index}, total_files) do
    Logger.metadata(filename: path)
    Logger.info("Parsing file #{path}")
    case Path.extname(path) do
      ".zip" ->
        case Processor.unarchive(path) do
          {:ok, files} ->
            files
            |> Enum.with_index
            |> Enum.each(fn {path, index} ->
              process_report_file(payment_check, {to_string(path), index}, total_files + Enum.count(files) - 1)
            end)
          {:error, reason} -> {:error, reason}
        end
      ".pdf" -> process_pdf_file(path, payment_check)
      _ -> nil
    end
  end

  defp process_pdf_file(path, payment_check) do
    content = case GenServer.call(Gt.Pdf.Parser, {:parse, path}) do
      nil -> {:error, "Can't parse pdf"}
      pages ->
        content = pages |> Enum.map(&to_string/1) |> Enum.join("")
        with %{"from" => from, "to" => to} <- period(content),
             %{"currency" => currency} <- currency(content),
             %{"in" => in_sum, "fee" => transaction_fee} <- service_commission(content),
             %{"out" => reverse_volume} <- reverse_volume(content),
             out <- parse_out(content),
             %{"fee_in" => fee_in} <- fee_in(content),
             %{"fee_out" => fee_out_commission} <- fee_out_commission(content),
             %{"fee_out" => fee_out_transaction} <- fee_out_transaction(content),
             %{"rate" => usd_rub_rate} <- parse_usd_rub_rate(content),
             %{"rate" => usd_eur_rate} <- parse_usd_eur_rate(content),
             %{"fee" => service_commission} <- parse_service_commission(content),
             %{"fee" => reverse_fee_out, "sum" => reverse_sum} <- reverse_fee_out(content),
             %{"merchant" => merchant} <- merchant(content) do
               create_source_report(path, from, to, merchant, currency)
               |> source_report_in(in_sum, currency)
               |> source_report_out(out, reverse_volume)
               |> source_report_fee_in(fee_in + transaction_fee, currency)
               |> source_report_fee_out(fee_out_commission + fee_out_transaction, reverse_fee_out, usd_rub_rate)
               |> source_report_extra(usd_rub_rate, usd_eur_rate, service_commission, reverse_sum)
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp create_source_report(path, from, to, merchant, currency) do
    %PaymentCheckSourceReport{}
    |> PaymentCheckSourceReport.changeset(%{
      filename: Path.basename(path),
      merchant: merchant,
      currency: currency,
      from: from,
      to: to
    })

  end

  defp source_report_in(source_report, in_sum, currency) do
    value = %PaymentCheckSourceValue{value: in_sum, currency: currency}
    Ecto.Changeset.put_embed(source_report, :in, [value])
  end

  defp source_report_out(source_report, out, reverse_volume) do
    reverse_value = %PaymentCheckSourceValue{value: reverse_volume, currency: "USD"}
    out_values = Enum.map(out, fn {value, currency, alternative_value, alternative_currency} ->
      out_value = %PaymentCheckSourceValue{value: value, currency: currency}
      alternative = %PaymentCheckSourceValue{value: alternative_value, currency: alternative_currency}
      Ecto.Changeset.put_embed(out_value, :alternatives, [alternative])
    end)
    Ecto.Changeset.put_embed(source_report, :out, [reverse_value | out_values])
  end

  defp source_report_fee_in(source_report, fee_in, currency) do
    value = %PaymentCheckSourceValue{value: fee_in, currency: currency}
    Ecto.Changeset.put_embed(source_report, :fee_in, [value])
  end

  defp source_report_fee_out(source_report, fee_out, reverse_fee_out, usd_rub_rate) do
    fee_out = if usd_rub_rate, do: fee_out * usd_rub_rate, else: fee_out
    value = %PaymentCheckSourceValue{value: fee_out, currency: "RUB"}
    reverse_fee_out_value = %PaymentCheckSourceValue{value: reverse_fee_out, currency: "USD"}
    Ecto.Changeset.put_embed(source_report, :fee_out, [value, reverse_fee_out_value])
  end

  defp source_report_extra(source_report, usd_rub_rate, usd_eur_rate, service_commission, reverse_sum) do
    PaymentCheckSourceReport.changeset(source_report, %{extra_data: %{
                                         "EUR_USD" => usd_eur_rate,
                                         "USD_RUB" => usd_rub_rate,
                                         "service_commission" => service_commission,
                                         "refund_commission" => reverse_sum
                                       }})
  end

  defp period(content) do
    case Regex.named_captures(~r/Period(?: \(transaction date\))?:\s*(?<from>[\d\/]+)-(?<to>[\d\/]+)/i, content) do
      nil -> {:error, "Failed to parse period"}
      matches -> matches
    end
  end

  defp currency(content) do
    case Regex.named_captures(~r/Currency:\s*(?<currency>\w{3})/i, content) do
      nil -> {:error, "Failed to parse currency"}
      matches -> matches
    end
  end

  defp service_commission(content) do
    {in_sum, fee} = case Regex.named_captures(~r/Service commission\s([-\d .]+)%\s(?<in>[-\d .,]+)\s(?<fee>[-\d .,]+)/i, content) do
      nil -> {0, 0}
      %{"in" => in_sum, "fee" => fee} -> {get_number(in_sum), get_number(fee)}
    end

    min_trans_in = case Regex.named_captures(~r/Service commission for minimal transactions?\s([-\d .,]+)%\s(?<in>[-\d .,]+)/i, content) do
      nil -> 0
      %{"in" => in_sum} -> get_number(in_sum)
    end

    min_trans_fee = case Regex.named_captures(~r/Transactional fee for minimal transactions?\s([-\d.,]+)\s([\d., ]+)\s(?<fee>[-\d., ]+)/i, content) do
      nil -> 0
      %{"fee" => fee} -> get_number(fee)
    end

    in_sum = in_sum + min_trans_in
    fee = fee + min_trans_fee

    if in_sum == 0 && fee == 0 do
      {:error, "Failed to parse \"in\""}
    else
      %{"in" => in_sum, "fee" => fee}
    end
  end

  defp reverse_volume(content) do
    out = case Regex.named_captures(~r/Purchase Reverse volume\s([\d\s-.,]+)\s([\d.,\s-]+)\s(?<amount>[\d.,\s-]+)/i, content) do
      nil -> 0
      %{"amount" => amount} -> get_number(amount) |> abs
    end
    %{"out" => out}
  end

  defp parse_out(content) do
    opts = [capture: ~w(currency sum rate to_currency)]
    Regex.scan(~r/Net total payouts.*?\s*(?<sum>[-\d. ]+)(?<currency>\w{3}) ?\((?<to_currency>\w{3})\/\w{3} rate(?<rate>[-\d. ]+)\)\s*([-\d. ]+)/i, content, opts)
    |> Enum.map(fn [currency, sum, rate, alternative_currency] ->
      value = get_number(sum)
      rate = get_number(rate)
      alternative_value = if rate != 0, do: value / rate, else: 0
      {value, currency, alternative_value, alternative_currency}
    end)
  end

  defp fee_in(content) do
    case Regex.named_captures(~r/Transactional fee\s*([-\d.,]+)\s([-\d., ]+)\s(?<fee>[-\d., ]+)\s/i, content) do
      nil -> {:error, "Failed to get \"Fee in\""}
      %{"fee" => fee} -> %{"fee" => get_number(fee)}
    end
  end

  defp fee_out_commission(content) do
    fee = case Regex.named_captures(~r/Service commission fee\s*(?<fee>[-\d., ]+)/i, content) do
      nil -> 0
      %{"fee" => fee} -> get_number(fee)
    end
    %{"fee" => fee}
  end

  defp fee_out_transaction(content) do
    fee = case Regex.named_captures(~r/Transactional fee\s(?<fee>[-\d. ]+)\s[^\d]/i, content) do
      nil -> 0
      %{"fee" => fee} -> get_number(fee)
    end
    %{"fee" => fee}
  end

  defp parse_service_commission(content) do
    case Regex.named_captures(~r/Service commission\s(?<fee>[\d.]+)/i, content) do
      nil -> {:error, "Failed to parse \"Service commission\""}
      %{"fee" => fee} -> %{"fee" => fee}
    end
  end

  defp parse_usd_rub_rate(content) do
    rate = case Regex.named_captures(~r/usd\/rub.*?(?<rate>[\d.]+)/i, content) do
      nil -> nil
      %{"rate" => rate} -> get_number(rate)
    end
    %{"rate" => rate}
  end

  defp parse_usd_eur_rate(content) do
    case Regex.named_captures(~r/EUR\/USD.*?(?<rate>[\d.]+)/i, content) do
      nil -> {:error, "Failed to parse USD/EUR rate"}
      %{"rate" => rate} -> %{"rate" => get_number(rate)}
    end
  end

  defp reverse_fee_out(content) do
    {sum, fee} = case Regex.named_captures(~r/Purchase Reverse Fee\s(?<fee>[\d\s-.]+)\s([\d\s-.]+)\s([\d.\s-]+)\s(?<sum>[\d.\s-]+)\s/i, content) do
      nil -> {0, 0}
      %{"fee" => fee, "sum" => sum} -> {get_number(sum), get_number(fee)}
    end
    %{"fee" => fee, "sum" => sum}
  end

  defp merchant(content) do
    case Regex.named_captures(~r/Merchant:\s(?<merchant>[\w\s]+)\sStatement/i, content) do
      nil -> {:error, "Failed to get merchant"}
      %{"merchant" => merchant} -> merchant
    end
  end

  defp get_number(value) when is_number(value) do
    if value == round(value), do: round(value), else: value
  end

  defp get_number(value) when is_bitstring(value) do
    case Float.parse(String.replace(value, " ", "")) do
      :error -> 0
      {number, _} -> get_number(number)
    end
  end

end
