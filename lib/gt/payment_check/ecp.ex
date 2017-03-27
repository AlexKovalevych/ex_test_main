defmodule Gt.PaymentCheck.Ecp do
  defstruct [:payment_check, :total_files]

  alias Gt.PaymentCheck.Processor
  alias Gt.PaymentCheckRegistry
  alias Gt.PaymentCheckSourceReport
  alias Gt.PaymentCheckSourceValue
  require Logger
  use Timex

  def process_secondary_file(payment_check, reports, {filename, report}) do
    path = Gt.Uploaders.PaymentCheck.local_path(payment_check.id, filename)
    Logger.metadata(filename: path)
    Logger.info("Parsing file #{path}")
    case Path.extname(path) do
      ".pdf" ->
        case GenServer.call(Gt.Pdf.Parser, {:parse, path}) do
          nil ->
            Logger.error("Failed to parse pdf #{path}")
            {:error, "Can't parse pdf"}
          pages ->
            content = pages |> Enum.map(&to_string/1) |> Enum.join("")
            with %{"from" => from, "to" => to} <- period(content),
                 %{"merchant" => merchant} <- parse_merchant(content) do
                   update_matched_report(reports, content, filename, merchant, from, to)
            else
              {:error, reason} ->
                Logger.info(reason)
                Map.put(report, :error, "pdf_error")
            end
        end
      _ -> nil
    end
  end

  defp update_matched_report(reports, content, filename, merchant, from, to) do
    matched_report = Enum.find(reports, fn report ->
      case :binary.match(report.merchant, merchant) do
        :nomatch -> false
        _ -> report.from == from && report.to == to
      end
    end)
    if !matched_report do
      message = "Can't find associated report file for #{filename}"
      Logger.error(message)
      raise message
    else
      report = with %{"currency" => currency} <- currency(content),
                    %{"out" => out} <- secondary_out(content),
                    fee <- secondary_fee_out(content) do
                    add_secondary_report(matched_report, content, currency, out, fee)
      else
        {:error, reason} ->
          Logger.info(reason)
          Map.put(matched_report, :error, "pdf_error")
      end
    end
  end

  def process_report_file(%{payment_check: payment_check} = struct, path) do
    Logger.metadata(filename: path)
    Logger.info("Parsing file #{path}")
    case Path.extname(path) do
      ".zip" ->
        case Processor.unarchive(path) do
          {:ok, files} ->
            files
            |> Enum.filter_map(
              fn file_path -> Path.dirname(file_path) == Path.dirname(path) end,
              fn file_path -> process_report_file(struct, to_string(file_path)) end
            )
          {:error, reason} -> {:error, reason}
        end
      ".pdf" -> process_pdf_file(path, payment_check)
      _ ->
        PaymentCheckRegistry.save(payment_check.id, {:log, path})
        nil
    end
  end

  defp process_pdf_file(path, payment_check) do
    Logger.metadata(filename: path)
    case GenServer.call(Gt.Pdf.Parser, {:parse, path}) do
      nil ->
        Logger.error("Failed to parse pdf #{path}")
        {:error, "Can't parse pdf"}
      pages ->
        report = %{
          filename: Path.basename(path),
          payment_check_id: payment_check.id
        }
        content = pages |> Enum.map(&to_string/1) |> Enum.join("")
        report = with %{"from" => from, "to" => to} <- period(content),
             %{"currency" => currency} <- currency(content),
             %{"in" => in_sum, "fee" => transaction_fee} <- service_commission(content),
             %{"out" => reverse_volume} <- reverse_volume(content),
             out <- parse_out(content),
             %{"fee" => fee_in} <- fee_in(content),
             %{"fee" => fee_out_commission} <- fee_out_commission(content),
             %{"fee" => fee_out_transaction} <- fee_out_transaction(content),
             %{"rate" => usd_rub_rate} <- parse_usd_rub_rate(content),
             %{"rate" => usd_eur_rate} <- parse_usd_eur_rate(content),
             %{"fee" => service_commission} <- parse_service_commission(content),
             %{"fee" => reverse_fee_out, "sum" => reverse_sum} <- reverse_fee_out(content),
             %{"merchant" => merchant} <- parse_merchant(content) do
               create_source_report(report, from, to, merchant, currency)
               |> source_report_extra(usd_rub_rate, usd_eur_rate, service_commission, reverse_fee_out)
               |> source_report_in(in_sum, currency)
               |> source_report_out(out, reverse_volume)
               |> source_report_fee_in(fee_in + transaction_fee, currency)
               |> source_report_fee_out(fee_out_commission + fee_out_transaction, reverse_sum, usd_rub_rate)
        else
          {:error, reason} ->
            Logger.info(reason)
            Map.put(report, :error, "pdf_error")
        end
        {Path.basename(path), report}
    end
  end

  defp create_source_report(source_report, from, to, merchant, currency) do
    Map.merge(source_report, %{
      merchant: merchant,
      currency: currency,
      from: from,
      to: to
    })
  end

  defp add_secondary_report(report, content, currency, out, fee) do
    out_value = %PaymentCheckSourceValue{value: out, currency: currency}
    fee_value = %PaymentCheckSourceValue{value: fee, currency: currency}
    extra_data = report.extra_data
    report = report
    |> Map.put(:out, [out_value | report.out])
    |> Map.put(:fee_out, [fee_value | report.fee_out])

    new_extra_data = if !Map.get(extra_data, "USD_RUB") do
      case parse_usd_rub_rate(content) do
        %{"rate" => usd_rub_rate} -> Map.put(extra_data, "USD_RUB", usd_rub_rate)
        _ -> extra_data
      end
    else
      extra_data
    end
    Map.put(report, :extra_data, Map.merge(report.extra_data, new_extra_data))
  end

  defp source_report_in(source_report, in_sum, currency) do
    Map.put(source_report, :in, [%PaymentCheckSourceValue{value: in_sum, currency: currency}])
  end

  defp source_report_out(source_report, out, reverse_volume) do
    reverse_value = %PaymentCheckSourceValue{value: reverse_volume, currency: "USD"}
    out_values = Enum.map(out, fn {value, currency, alternative_value, alternative_currency} ->
      alternative = %PaymentCheckSourceValue{value: alternative_value, currency: alternative_currency}
      %PaymentCheckSourceValue{value: value, currency: currency, alternatives: [alternative]}
    end)
    Map.put(source_report, :out, [reverse_value | out_values])
  end

  defp source_report_fee_in(source_report, fee_in, currency) do
    Map.put(source_report, :fee_in, [%PaymentCheckSourceValue{value: fee_in, currency: currency}])
  end

  defp source_report_fee_out(source_report, fee_out, reverse_fee_out, usd_rub_rate) do
    fee_out = if usd_rub_rate, do: fee_out * usd_rub_rate, else: fee_out
    value = %PaymentCheckSourceValue{value: fee_out, currency: "RUB"}
    reverse_fee_out_value = %PaymentCheckSourceValue{value: reverse_fee_out, currency: "USD"}
    Map.put(source_report, :fee_out, [value, reverse_fee_out_value])
  end

  defp source_report_extra(source_report, usd_rub_rate, usd_eur_rate, service_commission, reverse_sum) do
    Map.merge(source_report, %{
      extra_data: %{
        "EUR_USD" => usd_eur_rate,
        "USD_RUB" => usd_rub_rate,
        "service_commission" => service_commission,
        "refund_commission" => reverse_sum
    }})
  end

  defp period(content) do
    case Regex.named_captures(~r/Period(?: \(transaction date\))?:\s*(?<from>[\d\/]+)-(?<to>[\d\/]+)/i, content) do
      nil -> {:error, "Failed to parse period"}
      %{"from" => from, "to" => to} -> %{"from" => parse_pdf_date(from), "to" => parse_pdf_date(to)}
    end
  end

  defp parse_pdf_date(value) do
    case String.length(value) do
      10 -> Timex.parse!(value, "{0D}/{0M}/{YYYY}") |> Timex.to_date
    end
  end

  defp currency(content) do
    case Regex.named_captures(~r/Currency:\s*(?<currency>\w{3})/i, content) do
      nil -> {:error, "Failed to parse currency"}
      matches -> matches
    end
  end

  defp service_commission(content) do
    {in_sum, fee, matched} = case Regex.named_captures(~r/Service commission\s([-\d .]+)%\s(?<in>[-\d .,]+)\s(?<fee>[-\d .,]+)/i, content) do
      nil -> {0, 0, false}
      %{"in" => in_sum, "fee" => fee} -> {get_number(in_sum), get_number(fee), true}
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

    if !matched do
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

  defp secondary_out(content) do
    case Regex.named_captures(~r/(Net total payouts|Net total cards payouts|Cards total payouts).*?\s*(?<sum>[-\d. ]+)/i, content) do
      nil -> {:error, "Failed to get secondary out"}
      %{"sum" => sum} -> %{"out" => abs(get_number(sum))}
    end
  end

  defp secondary_fee_out(content) do
    fee = case Regex.named_captures(~r/Service commission for transaction[s]?\s+([\d.]+)%\s([\d\s.]+)\s([-\d.\s]+)\n(?<fee>[-\d\s.]+)\s/i, content) do
      nil -> 0
      %{"fee" => fee} -> get_number(fee)
    end

    fee = fee + case Regex.named_captures(~r/Transaction[s]?al fee for transaction[s]?\s+([\d.]+)\s([\d\s.]+)\s([-\d.\s]+)\n(?<fee>[-\d\s.]+)\s/i, content) do
      nil -> 0
      %{"fee" => fee} -> get_number(fee)
    end

    fee + case Regex.named_captures(~r/Transaction[s]?al fee for minimal transaction[s]?\s+([\d.]+)\s([\d\s.]+)\s([-\d.\s]+)\n(?<fee>[-\d\s.]+)\s/i, content) do
      nil -> 0
      %{"fee" => fee} -> get_number(fee)
    end
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
    case Regex.named_captures(~r/EUR\/USD\srate:\s(?<rate>[\s\d.]+)\s/i, content) do
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

  defp parse_merchant(content) do
    case Regex.named_captures(~r/Merchant:\s(?<merchant>[\w\s \.]+)\sStatement/i, content) do
      nil -> {:error, "Failed to get merchant"}
      %{"merchant" => merchant} -> %{"merchant" => merchant}
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

defimpl Gt.PaymentCheck.Script, for: Gt.PaymentCheck.Ecp do
  alias Gt.PaymentCheck.Ecp
  alias Gt.PaymentCheckSourceReport
  alias Gt.PaymentCheck.Processor
  alias Gt.PaymentCheckRegistry
  alias Gt.PaymentCheckTransaction
  alias Gt.OneGamepayTransaction
  alias Gt.Repo
  require Logger

  @min_in_usd_fee 0.6
  @min_out_rub_fee 75.01
  @base_eur_fee 0.15
  @min_service_out_rub_modifier 25

  @merchant_darmako "DARMACO TRADING LIMITED"
  @merchant_ggs "GGS NET LTD"

  def preprocess(%{payment_check: payment_check} = struct) do
    source_reports = payment_check.files
    |> Enum.reduce(%{}, fn filename, acc ->
      Logger.info("Processing #{filename} file")
      path = Gt.Uploaders.PaymentCheck.local_path(payment_check.id, filename)
      source_report = Ecp.process_report_file(struct, path)
      cond do
        is_list(source_report) ->
          source_report
          |> Enum.filter(fn
            {:error, _} -> false
            nil -> false
            _ -> true
          end)
          |> Enum.reduce(acc, fn {filename, report}, reports ->
            Map.put(reports, filename, report)
          end)
        is_tuple(source_report) ->
          {filename, report} = source_report
          Map.put(acc, filename, report)
        true -> acc
      end
    end)

    success_reports = source_reports
                      |> Enum.filter_map(
                        fn {_, report} -> !Map.has_key?(report, :error) end,
                        fn {_, report} ->
                          PaymentCheckRegistry.save(payment_check.id, {:report, report})
                          report
                        end
                      )

    source_reports
    |> Enum.filter_map(
      fn {_, report} -> Map.has_key?(report, :error) end,
      &(Ecp.process_secondary_file(payment_check, success_reports, &1))
    )
    |> Enum.map(fn report ->
      report = if !Map.has_key?(report, :error) do
        in_v = report.in |> Enum.with_index |> Enum.map(fn {v, k} -> {to_string(k), v} end) |> Enum.into(%{})
        out = report.out |> Enum.with_index |> Enum.map(fn {v, k} -> {to_string(k), v} end) |> Enum.into(%{})
        fee_in = report.fee_in |> Enum.with_index |> Enum.map(fn {v, k} -> {to_string(k), v} end) |> Enum.into(%{})
        fee_out = report.fee_out |>Enum.with_index |> Enum.map(fn {v, k} -> {to_string(k), v} end) |> Enum.into(%{})
        report
        |> Map.put(:in, in_v)
        |> Map.put(:out, out)
        |> Map.put(:fee_in, fee_in)
        |> Map.put(:fee_out, fee_out)
      else
        report
      end
      report = %PaymentCheckSourceReport{}
      |> PaymentCheckSourceReport.changeset(report)
      |> Repo.insert!
      if !report.error do
        PaymentCheckRegistry.save(payment_check.id, {:report, report})
      end
    end)

    files = PaymentCheckRegistry.find(payment_check.id, :log) |> Enum.map(&Path.basename/1)
    {%{struct | total_files: Enum.count(files)}, files}
  end

  def sum_1gp(_struct, transaction, one_gamepay_transaction) do
    if transaction.type == PaymentCheckTransaction.type(:in) do
      Gt.CbrProvider.to_usd(one_gamepay_transaction.currency,
                            Timex.to_date(one_gamepay_transaction.date),
                            abs(one_gamepay_transaction.sum))
      |> Float.round(2)
    else
      Processor.sum_1gp(one_gamepay_transaction)
    end
  end

  def channel_sum_1gp(_struct, transaction, one_gamepay_transaction) do
    if transaction.type == PaymentCheckTransaction.type(:in) do
      Gt.CbrProvider.to_usd(one_gamepay_transaction.channel_currency,
                            Timex.to_date(one_gamepay_transaction.date),
                            abs(one_gamepay_transaction.channel_sum))
      |> Float.round(2)
    else
      Processor.channel_sum_1gp(one_gamepay_transaction)
    end
  end

  def match_1gp_sum(_struct, transaction, one_gamepay_sum, one_gamepay_channel_sum) do
    trans_sum = transaction.sum
    if Processor.match_1gp_sum(transaction, one_gamepay_sum, one_gamepay_channel_sum) do
      true
    else
      channel_sum_percent_diff = abs(100 - (one_gamepay_channel_sum * 100 / trans_sum))
      sum_percent_diff = abs(100 - (one_gamepay_channel_sum * 100 / trans_sum))

      # percent diff, add error, if > 3%, or sum diff > 5 USD
      if channel_sum_percent_diff > 3 && sum_percent_diff > 3 do
        if abs(trans_sum - one_gamepay_channel_sum) > 5 && abs(trans_sum - one_gamepay_channel_sum) > 5 do
          false
        else
          true
        end
      else
        true
      end
    end
  end

  def currency_1gp(_struct, %{type: type, currency: currency}) do
    type_out = OneGamepayTransaction.type(:out)
    case type do
      ^type_out -> currency
      _ -> "USD"
    end
  end

  def channel_currency_1gp(_struct, %{type: type, channel_currency: currency}) do
    type_out = OneGamepayTransaction.type(:out)
    case type do
      ^type_out -> currency
      _ -> "USD"
    end
  end

  def calculate_fee(%{payment_check: payment_check}, transaction) do
    transaction = if transaction.type == PaymentCheckTransaction.type(:in) do
      # Time is shifted by 23 minutes for in transactions
      %{transaction | date: Timex.shift(transaction.date, minutes: -23)}
    else
      transaction
    end

    is_refund = Map.get(transaction.source, "Refund", 0) != 0 || Map.get(transaction.source, "Purchase Reversal", 0) != 0
    transaction = if transaction.type == PaymentCheckTransaction.type(:out) do
      case is_refund do
        true ->
          report = find_source_report(transaction, payment_check)
          %{transaction | fee: report.extra_data["refund_commission"]}
        _ ->
          %{transaction | sum: transaction.sum / 100,
                          report_sum: transaction.report_sum / 100}
      end
    else
      transaction
    end

    transaction = if Enum.member?(payment_check.ps["fee"]["types"], transaction.type) && !is_refund do
      fee_sum = case payment_check.ps["fee"]["fee_report"] do
        true ->
          :report_sum
        _ ->
          :sum
      end

      transaction = %{transaction | fee: transaction.fee + Processor.parse_float(Map.get(payment_check.ps["fee"], "sum"))}

      # transaction have minimal fee, or percent + fix price fee
      # in and out have different minimal transactions sum
      source_report = find_source_report(transaction, payment_check)
      in_transaction_percent = get_service_commission(source_report)
      out_transaction_percent = payment_check.ps["fields"]["fee_out_percent"]
      type_in = PaymentCheckTransaction.type(:in)
      type_out = PaymentCheckTransaction.type(:out)
      cond do
        minimal_in_transaction?(payment_check, transaction, in_transaction_percent, source_report) ->
          rate = get_rate(source_report, "USD", transaction.fee_currency)
          %{transaction | fee: convert_value(rate, @min_in_usd_fee)}
        minimal_out_transaction?(payment_check, transaction, out_transaction_percent, source_report) ->
          rate = get_rate(source_report, "RUB", transaction.fee_currency)
          %{transaction | fee: convert_value(rate, @min_out_rub_fee)}
        true ->
          # calculate default fee rules
          {trans_percent, transaction} = case transaction.type do
            ^type_out ->
              fix_out_fee = payment_check.ps["fields"]["fee_sum_rub"]
              rate = get_rate(source_report, "RUB", transaction.fee_currency)
              fee = Float.round(convert_value(rate, fix_out_fee), 2)
              {out_transaction_percent, %{transaction | fee: transaction.fee + fee}}
            _ ->
              {in_transaction_percent, transaction}
          end
          fee_sum = case payment_check.ps["fee"]["fee_report"] do
            true -> transaction.report_sum
            false -> transaction.sum
          end
          fee_percent = trans_percent / 100 * fee_sum
          fee_sum = fee_percent + case transaction.type do
            ^type_in ->
              rate = get_rate(source_report, "EUR", "USD")
              Float.round(convert_value(rate, @base_eur_fee), 2)
            _ -> 0
          end
          %{transaction | fee: transaction.fee + fee_sum}
      end
    else
      transaction
    end

    max_fee = Map.get(payment_check.ps["fee"], "max_fee")
    fee = if max_fee && transaction.fee > max_fee, do: max_fee, else: transaction.fee
    %{transaction | fee: fee}
  end

  defp minimal_in_transaction?(payment_check, transaction, percent_in, source_report) do
    # comission only for transactions from 2016-03-21
    if transaction.type != PaymentCheckTransaction.type(:in) do
      false
    else
      {sum, currency} = case payment_check.ps["fee"]["fee_report"] do
        true -> {transaction.report_sum, transaction.report_currency}
        false -> {transaction.sum, transaction.currency}
      end
      rate = get_rate(source_report, "USD", currency)
      usd_sum = convert_value(rate, sum)
      rate = get_rate(source_report, "EUR", "USD")
      min_trans_sum = Float.round((@min_in_usd_fee - Float.round(@base_eur_fee * rate, 2)) / percent_in * 100, 2)
      IO.inspect([usd_sum, min_trans_sum])
      usd_sum < min_trans_sum
    end
  end

  defp minimal_out_transaction?(payment_check, transaction, percent_out, source_report) do
    if transaction.type != PaymentCheckTransaction.type(:out) do
      false
    else
      {sum, currency} = case payment_check.ps["fee"]["fee_report"] do
        true -> {transaction.report_sum, transaction.report_currency}
        false -> {transaction.sum, transaction.currency}
      end
      min_out_trans_rub_sum = @min_service_out_rub_modifier / (percent_out / 100)
      rate = get_rate(source_report, "RUB", currency)
      min_sum = Float.round(convert_value(rate, min_out_trans_rub_sum), 2)
      sum < min_sum
    end
  end

  defp get_rate(_, from, from), do: 1

  defp get_rate(report, from, to) do
    key = "#{from}_#{to}"
    reverse_key = "#{to}_#{from}"
    case Map.get(report.extra_data, key) do
      nil ->
        case Map.get(report.extra_data, reverse_key) do
          nil ->
            message = "Required rate #{from}-#{to} not found"
            Logger.error(message)
            raise message
          rate -> 1 / rate
        end
      rate -> rate
    end
  end

  defp convert_value(rate, value), do: rate * value

  defp get_service_commission(%{extra_data: extra_data}) do
    Map.get(extra_data, "service_commission", "0") |> Float.parse |> elem(0)
  end

  def find_source_report(transaction, payment_check) do
    account = transaction.account_id
    ggs_merchants = String.split(payment_check.ps["fields"]["ggs_merchants"], ",")
    darmako_merchants = String.split(payment_check.ps["fields"]["darmako_merchants"], ",")

    merchant = Enum.reduce_while(ggs_merchants, nil, fn ggs_merchant, acc ->
      case :binary.match(account, ggs_merchant) do
        :nomatch -> {:cont, acc}
        _ -> {:halt, @merchant_ggs}
      end
    end)

    merchant = if !merchant do
      Enum.reduce_while(darmako_merchants, nil, fn darmako_merchant, acc ->
        case :binary.match(account, darmako_merchant) do
          :nomatch -> {:cont, acc}
          _ -> {:halt, @merchant_darmako}
        end
      end)
    else
      merchant
    end

    date = transaction.date |> Timex.to_date
    if !merchant do
      Logger.error("Invalid merchant #{account}")
      raise "Invalid merchant"
    else
      source_report = payment_check.id
                      |> PaymentCheckRegistry.find(:report)
                      |> Enum.find(fn report ->
                        usd_rub = Map.get(report.extra_data, "USD_RUB")
                        eur_usd = Map.get(report.extra_data, "EUR_USD")
                        source_report_in = if !Enum.empty?(report.in) do
                          report.in
                          |> Enum.reduce_while(0, fn in_value, acc ->
                            in_value = case in_value do
                              {_, v} -> v
                              v -> v
                            end
                            if in_value.value != 0 && in_value.currency == "USD" do
                              {:halt, in_value.value}
                            else
                              {:cont, acc}
                            end
                          end)
                        else
                          0
                        end

                        invalid_pdf = (usd_rub == 1 && eur_usd == 1) ||
                                      (transaction.type == PaymentCheckTransaction.type(:in) && source_report_in == 0)

                        report.merchant == merchant &&
                        Timex.diff(report.from, date) <= 0 &&
                        Timex.diff(report.to, date) >= 0 &&
                        !invalid_pdf
                      end)

      if !source_report do
        Logger.error("Can't find #{merchant} merchant for #{account} for date #{date}")
        raise "Invalid merchant"
      else
        source_report
      end
    end
  end

  def parse_date(struct, path, cell) do
    date = Processor.parse_date(struct, cell)
    case Regex.named_captures(~r/(?<from>\d{4}'\d{2}'\d{2})-(?P<to>\d{4}'\d{2}'\d{2})/, Path.basename(path)) do
      %{"from" => from, "to" => to} ->
        from = String.replace(from, "'", "-") |> Timex.parse!("{YYYY}-{0M}-{0D}") |> Timex.set(hour: 10)
        to = String.replace(to, "'", "-") |> Timex.parse!("{YYYY}-{0M}-{0D}") |> Timex.set(hour: 23, minute: 59, second: 59)
        cond do
          Timex.diff(date, from) < 0 -> from
          Timex.diff(date, to) > 0 -> to
          true -> date
        end
      nil -> date
    end
  end
end
