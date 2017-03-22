defmodule Gt.PaymentCheckRegistry do
  use GenServer
  alias Gt.PaymentCheckTransaction
  alias Gt.PaymentCheckSourceReport
  import String, only: [to_atom: 1]

  def create(id) do
    :ets.new(get_key(id), [:named_table, :public])
  end

  def save(id, key, value) do
    :ets.insert(get_key(id), {key, value})
  end

  def save(id, %PaymentCheckTransaction{id: transaction_id} = transaction) do
    :ets.insert(get_key(id), {"transaction_#{transaction_id}", "transaction", transaction})
  end

  def save(id, {:report, report}) do
    :ets.insert(get_key(id), {"report_#{report.filename}", "report", report.merchant, report.from, report.to, report})
  end

  def save(id, {:log, path}) do
    :ets.insert(get_key(id), {"log_#{path}", "log", path})
  end

  def increment(id, key, value \\ 1) do
    :ets.update_counter(get_key(id), key, {2, value})
  end

  def delete(id) do
    try do
      :ets.delete(get_key(id))
    rescue
      _ in ArgumentError -> nil
    end
  end

  def find(id, "transaction" = key) do
    :ets.match(get_key(id), {:"_", key, :"$1"}) |> Enum.concat
  end

  def find(id, "report" = key) do
    :ets.match(get_key(id), {:"_", key, :"_", :"_", :"_", :"$1"}) |> Enum.concat
  end

  def find(id, "log" = key) do
    :ets.match(get_key(id), {:"_", key, :"$1"}) |> Enum.concat
  end

  def find(id, {merchant, from, to}) do
    :ets.match(get_key(id), {:"_", "report", :"_", from, to, :"$1"})
    |> Enum.concat
    |> Enum.filter(fn report ->
      case :binary.match(report.merchant, merchant) do
        :nomatch -> false
        _ -> true
      end
    end)
  end

  def find(id, key) when is_atom(key) do
    try do
      case :ets.lookup(get_key(id), key) do
        [{_id, value}] -> value
        [] -> nil
      end
    rescue
      _ in ArgumentError -> nil
    end
  end

  ###
  # GenServer API
  ###
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defp get_key(id) do
    "payment_check_#{id |> to_string}" |> to_atom
  end

end
