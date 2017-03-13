defmodule Gt.PaymentCheck.Processor do
  alias Gt.OneGamepayTransaction
  alias Gt.PaymentCheck
  alias Gt.PaymentCheckRegistry
  alias Gt.PaymentCheckTransaction
  alias Gt.PaymentCheckTransactionError
  alias Gt.Payment
  alias Gt.Repo
  require Ecto.Query
  require Logger
  use Timex

  @callback run(payment_check :: %PaymentCheck{}) :: any

  def run(payment_check) do
    total_files = Enum.count(payment_check.files)
    Logger.info("Processing #{total_files} files")
    PaymentCheckRegistry.save(payment_check.id, :total, 0)
    payment_check.files
    |> Enum.with_index
    |> Enum.map(fn {filename, index} ->
      Logger.info("Processing #{filename} file")
      process_file(payment_check, {Gt.Uploaders.PaymentCheck.local_path(payment_check.id, filename), index}, total_files)
    end)
  end

  def process_file(payment_check, {path, index}, total_files) do
    Logger.metadata(filename: path)
    case Path.extname(path) do
      ".zip" ->
        Logger.info("Extracting #{path}")
        case :zip.unzip(path |> String.to_charlist, [{:cwd, Path.dirname(path) |> String.to_charlist}]) do
          {:ok, files} ->
            Logger.info("Extracted #{Enum.count(files)} from #{path}")
            files
            |> Enum.with_index
            |> Enum.each(fn {path, index} ->
              process_file(payment_check, {to_string(path), index}, total_files + Enum.count(files) - 1)
            end)
        end
      ".csv" ->
        Logger.info("Parsing file")
        #PaymentCheckRegistry.save(payment_check.id, :header, 0)
        separator = get_separator(payment_check)
        double_qoute = get_double_qoute(payment_check)
        headers = File.stream!(path)
                  |> CSV.decode(separator: separator, double_qoute: double_qoute)
                  |> Stream.take_while(fn row ->
                    headers = parse_headers(payment_check, row)
                  end)

      _ ->
        Logger.info("Parsing file")
        path
        |> Exoffice.parse()
        |> Enum.with_index()
        |> Enum.map(fn
            {{:ok, pid, parser}, sheet} ->
              rows_number = Exoffice.count_rows(pid, parser)
              Logger.info("Found #{rows_number} rows in sheet #{sheet}")
              PaymentCheckRegistry.increment(payment_check.id, :total, rows_number * 2)
              stream = Exoffice.get_rows(pid, parser)
              |> Stream.drop_while(fn row ->
                if parse_headers(payment_check, row) do
                  true
                else
                  PaymentCheckRegistry.increment(payment_check.id, :processed, 2)
                  false
                end
              end)
              |> Stream.chunk(10, 10, [])
              |> Stream.each(fn chunk ->
                ParallelStream.each(chunk, fn row ->
                  PaymentCheckRegistry.increment(payment_check.id, :processed)
                  parse_row(payment_check, row)
                end)
                |> Enum.reduce(nil, fn _, _ -> nil end)
              end)
              |> Enum.reduce(0, fn _, acc -> acc + 1 end)
              Exoffice.close(pid, parser)

              Logger.info("Matching with 1gamepay")
              PaymentCheckRegistry.find(payment_check.id, "transaction")
              |> Enum.chunk(10, 10, [])
              |> Enum.each(fn chunk ->
                chunk
                |> ParallelStream.each(&compare_1gp(payment_check, &1))
                |> Enum.reduce(nil, fn _, _ -> nil end)
              end)
        end)
    end
  end

  def parse_headers(payment_check, row) do
    headers = ~w(map_id sum currency date type account_id state player_purse)
              |> parse_headers_block(payment_check, "fields", "", %{})

    headers = ~w(map_id payment_system)
              |> parse_headers_block(payment_check, "one_gamepay", "1gp_", headers)

    headers = ~w(map_id currency)
              |> parse_headers_block(payment_check, "fee", "fee_", headers)

    headers = ~w(sum currency)
              |> parse_headers_block(payment_check, "report", "report_", headers)

    matched_headers = row
    |> Enum.with_index
    |> Enum.reduce(%{}, fn {cell, index}, acc ->
      cell = sanitize(cell)
      case Enum.find(headers, fn {_, values} -> !is_nil(Enum.find_index(values, fn v -> v == cell end)) end) do
        {key, _} -> Map.put(acc, index, key)
        _ -> acc
      end
    end)
    if Enum.all?(~w(map_id sum date), &(Map.values(matched_headers) |> Enum.member?(&1))) do
      Logger.info("Found headers: #{inspect(matched_headers)}")
      PaymentCheckRegistry.save(payment_check.id, :headers, matched_headers)
      PaymentCheckRegistry.save(payment_check.id, :source_headers, row)
      true
    else
      false
    end
  end

  def parse_row(payment_check, row) do
    headers = PaymentCheckRegistry.find(payment_check.id, :headers)
    source_headers = PaymentCheckRegistry.find(payment_check.id, :source_headers)
    fields = payment_check.ps["fields"]
    transaction = %PaymentCheckTransaction{
      payment_check_id: payment_check.id,
      source: Enum.zip(source_headers, row) |> Enum.into(%{}),
      type: fields["default_payment_type"]
    }
    transaction = row
    |> Enum.with_index
    |> Enum.reduce(transaction, fn {cell, index}, acc ->
      cell = sanitize(cell)
      case Map.get(headers, index, nil) do
        "map_id" -> %{acc | ps_trans_id: to_string(cell)}
        "sum" -> %{acc | sum: parse_float(cell)}
        "currency" -> %{acc | currency: parse_currency(cell)}
        "date" -> %{acc | date: parse_date(cell)}
        "type" -> %{acc | type: parse_type(fields["default_payment_type"], fields["type_in"], fields["type_out"], cell)}
        "account_id" -> %{acc | account_id: cell}
        "state" -> %{acc | state: cell}
        "player_purse" -> %{acc | player_purse: cell}
        "1gp_map_id" -> %{acc | one_gamepay_id: parse_one_gamepay_id(cell)}
        "comment" -> %{acc | comment: cell}
        "fee_map_id" -> %{acc | fee_id: cell} # this field is not mapped
        "fee_currency" -> %{acc | fee_currency: parse_currency(cell)}
        "report_sum" -> %{acc | report_sum: parse_float(cell)}
        "report_currency" -> %{acc | report_currency: parse_currency(cell)}
        nil -> acc
      end
    end)
    |> divide_100(payment_check)
    |> calculate_fee(payment_check)
    |> set_account(payment_check.ps["fields"]["default_account_id"], :account_id)
    |> set_account(payment_check.ps["fee"]["default_account_id"], :fee_account_id)
    transaction = PaymentCheckTransaction.changeset(transaction) |> Repo.insert!()
    PaymentCheckRegistry.save(payment_check.id, transaction)
  end

  @doc """
  Compare with 1Gamepay transactions
  """
  def compare_1gp(payment_check, transaction) do
    cond do
      # Wrong type
      !Enum.member?(PaymentCheckTransaction.types(), transaction.type) ->
        PaymentCheckTransaction.changeset(transaction, %{skipped: true}) |> Repo.update!

      true ->
        compare_result = find_1gp_transaction(payment_check, transaction)
                         |> validate_date()
                         |> one_gamepay_duplicates(payment_check)
                         |> compare_sum()
                         |> compare_currency()
                         |> set_lang()
                         |> set_1gp_trans_id()
        {transaction, _, errors} = compare_result
        transaction
        |> Ecto.Changeset.put_embed(:errors, errors)
        |> Repo.update!()
    end
    PaymentCheckRegistry.increment(payment_check.id, :processed)
  end

  def find_1gp_transaction(payment_check, transaction) do
    case OneGamepayTransaction.by_payment_check_transaction(payment_check, transaction) |> Repo.one do
      nil -> {transaction, nil, [add_1gp_error(:not_found)]}
      one_gamepay_transaction -> {transaction, one_gamepay_transaction, []}
    end
  end

  @doc"""
  Search for duplicates among payment check transactions
  """
  def one_gamepay_duplicates({_, nil, _} = result, _), do: result

  def one_gamepay_duplicates({transaction, one_gamepay_transaction, errors} = result, payment_check) do
    duplicate = PaymentCheckTransaction.duplicate(payment_check.id, transaction.id, one_gamepay_transaction.trans_id)
    |> Repo.one
    if duplicate do
      {transaction, one_gamepay_transaction, [add_1gp_error(:duplicate) | errors]}
    else
      result
    end
  end

  @doc"""
  Compare transaction sum with 1Gamepay sum
  """
  def compare_sum({_, nil, _} = result) , do: result

  def compare_sum({transaction, one_gamepay_transaction, _} = result) do
    if abs(transaction.sum) != abs(one_gamepay_transaction.sum) &&
       abs(transaction.sum) != abs(one_gamepay_transaction.channel_sum) do
      {transaction, one_gamepay_transaction, [add_1gp_error(:invalid_sum)]}
    else
      result
    end
  end

  @doc"""
  Compare transaction currency with 1Gamepay currency
  """
  def compare_currency({_, nil, _} = result), do: result

  def compare_currency({transaction, one_gamepay_transaction, errors} = result) do
    if transaction.currency != one_gamepay_transaction.currency &&
       transaction.currency != one_gamepay_transaction.channel_currency do
      {transaction, one_gamepay_transaction, [add_1gp_error(:invalid_currency)]}
    else
      result
    end
  end

  def set_1gp_trans_id({transaction, nil, errors}), do: {PaymentCheckTransaction.changeset(transaction), nil, errors}

  def set_1gp_trans_id({transaction, one_gamepay_transaction, errors}) do
    {
      PaymentCheckTransaction.changeset(transaction, %{one_gamepay_transaction_id: one_gamepay_transaction.id}),
      one_gamepay_transaction,
      errors
    }
  end

  def set_lang({_, nil, _} = result), do: result

  def set_lang({transaction, one_gamepay_transaction, errors} = result) do
    payment = Payment
              |> Payment.by_project_item_id(one_gamepay_transaction.project_id, one_gamepay_transaction.project_trans_id)
              |> Ecto.Query.preload(:project_user)
              |> Repo.one
    if payment do
      transaction = transaction
      |> PaymentCheckTransaction.changeset(%{
        lang: payment.project_user.lang
      })
      {transaction, one_gamepay_transaction, errors}
    else
      result
    end

  end

  @doc"""
  Check if transaction has valid date
  """
  def validate_date({transaction, one_gamepay_transaction, errors} = result) do
    if !transaction.date do
      {transaction, one_gamepay_transaction, [add_1gp_error(:invalid_date) | errors]}
    else
      result
    end
  end

  def add_1gp_error(message) do
    %PaymentCheckTransactionError{}
    |> PaymentCheckTransactionError.changeset(%{
        type: PaymentCheckTransactionError.type(:"1gp"),
        message: PaymentCheckTransactionError.message(message)
    })
  end

  def get_separator(payment_check) do
    case payment_check.ps["csv"]["separator"] do
      "comma" -> ?,
      "tab" -> ?\t
      "colon" -> ?:
      "pipe" -> ?|
      "space" -> ?\s
      "semicolon" -> ?;
      _ -> ?,
    end
  end

  def get_double_qoute(payment_check) do
    case payment_check.ps["csv"]["double_qoute"] do
      "double_qoute" -> ?"
      "single_qoute" -> ?'
      _ -> ?"
    end
  end

  def sanitize(value) when is_binary(value) do
    value
    |> String.replace("\"\"", "")
    |> String.replace(~r/^=\"/, "\"")
    |> String.trim("\"")
    |> String.trim()
    |> remove_utf8_bom()
  end

  def sanitize(value), do: value

  def remove_utf8_bom(value) do
    {:ok, reg} = Regex.compile("^" <> <<239, 187, 191>>)
    String.replace(value, reg, "")
  end

  def parse_float(value) when is_float(value), do: value

  def parse_float(value) when is_integer(value), do: value / 1

  def parse_float(value) when is_bitstring(value) do
    value
    |> String.replace(",", ".")
    |> String.replace(" ", "")
    |> String.to_float()
  end

  def parse_currency(value) do
    case Integer.parse(value) do
      {code, ""} -> Gt.Currency.Cache.find(code)
      _ -> value
    end
  end

  def parse_date(value) when is_binary(value) do
    value = value
    |> String.replace("(", "")
    |> String.replace(")", "")
    case String.length(value) do
      19 -> Timex.parse!(value, "{ISO} {ISOtime}")
      25 -> Timex.parse!(value, "{ISOdate} {ISOtime}{Z:}")
      _ ->
        Logger.error("Failed to parse date #{value}")
        nil
    end
  end

  def parse_date({date, time} = value) when is_tuple(date) and is_tuple(time) do
    case NaiveDateTime.from_erl(value) do
      {:ok, date} -> date
      _ ->
        Logger.error("Failed to parse date #{inspect(value)}")
        nil
    end
  end

  def parse_date(value) when is_tuple(value) do
    case Date.from_erl(value) do
      {:ok, date} -> date |> Timex.to_naive_datetime
      _ ->
        Logger.error("Failed to parse date #{inspect(value)}")
        nil
    end
  end

  def parse_type(default_type, type_in, type_out, value) do
    cond do
      !is_nil(type_in) && String.split(type_in, ",") |> Enum.member?(value) ->
        PaymentCheckTransaction.type(:in)
      !is_nil(type_out) && String.split(type_out, ",") |> Enum.member?(value) ->
        PaymentCheckTransaction.type(:out)
      true ->
        Logger.info("Unknown type #{value}, using default: #{default_type}")
        value
    end
  end

  def parse_one_gamepay_id(value) when is_bitstring(value) do
    case Regex.run(~r/\d+/, value) do
      [id] -> id |> String.to_integer
      _ -> nil
    end
  end

  def parse_one_gamepay_id(value) when is_integer(value), do: value

  def calculate_fee(transaction, payment_check) do
    if Enum.member?(payment_check.ps["fee"]["types"], transaction.type) do
      fee_sum = case payment_check.ps["fee"]["fee_report"] do
        true -> "report_sum"
        _ -> "sum"
      end
      fixed_fee = get_float(Map.get(payment_check.ps["fee"], fee_sum))
      percent_fee = get_float(Map.get(payment_check.ps["fee"], "percent")) / 100 * transaction.sum
      fee = fixed_fee + percent_fee
      max_fee = Map.get(payment_check.ps["fee"], "max_fee")
      fee = if max_fee && fee > max_fee, do: max_fee, else: fee
      %{transaction | fee: fee}
    else
      transaction
    end
  end

  @doc """
  TODO: This should be improved to have strict check for default_account_id
  """
  def set_account(transaction, default_account_id, field) do
    cond do
      is_nil(default_account_id) -> transaction
      :binary.match(default_account_id, "#") != :nomatch ->
        try do
          account = Code.eval_string("\"#{default_account_id}\"", transaction: transaction)
          Map.put(transaction, field, account)
        rescue
          _ ->
            Logger.error("Invalid account pattern #{default_account_id}")
            transaction
        catch
          _ ->
            Logger.error("Invalid account pattern #{default_account_id}")
            transaction
        end
      !is_nil(default_account_id) -> Map.put(transaction, field, default_account_id)
      true -> transaction
    end
  end

  def divide_100(transaction, payment_check) do
    transaction = case payment_check.ps["fee"]["divide_100"] do
      true -> %{transaction | sum: transaction.sum / 100, fee: transaction.fee / 100}
      _ -> transaction
    end
    case payment_check.ps["report"]["divide_100"] do
      true -> %{transaction | report_sum: transaction.report_sum / 100}
      _ -> transaction
    end
  end

  def get_float(nil), do: 0.0

  def get_float(value) when is_float(value), do: value

  def get_float(value) when is_integer(value), do: value / 1

  defp parse_headers_block(fields, payment_check, block, prefix, headers) do
    fields
    |> Enum.filter(fn key -> !is_nil(payment_check.ps[block][key]) end)
    |> Enum.reduce(headers, fn key, acc ->
      values = payment_check.ps[block][key] |> String.split(",")
      Map.put(acc, "#{prefix}#{key}", values)
    end)
  end

end
