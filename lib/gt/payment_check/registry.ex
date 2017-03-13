defmodule Gt.PaymentCheckRegistry do
  use GenServer
  alias Gt.PaymentCheckTransaction
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
