defmodule Gt.PaymentCheck.Ecp do
  @behaviour Gt.PaymentCheck.Processor

  alias Gt.PaymentCheck.Processor
  alias Gt.OneGamepayTransaction
  alias Gt.PaymentCheck
  alias Gt.PaymentCheckRegistry
  alias Gt.PaymentCheckTransaction
  alias Gt.PaymentCheckTransactionError
  #alias Gt.Payment
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
             %{"currency" => currency} <- currency(content)
        else
          {:error, reason} -> {:error, reason}
        end
    end
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

  def service_commission(content) do
    case Regex.named_captures(~r/Service commission\s([-\d .]+)%\s(?<in>[-\d .,]+)\s(?<fee>[-\d .,]+)/i, content) do
      nil -> {0, 0}
      %{"in" => in, "fee" => fee} -> {in, fee}
    end
  end

end
