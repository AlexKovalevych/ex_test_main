defmodule Gt.Currency.Cache do
  use GenServer
  import String, only: [to_atom: 1]
  import SweetXml

  def save(key, value) do
    :ets.insert(__MODULE__, {to_atom(key), value})
  end

  def find(key) do
    case :ets.lookup(__MODULE__, to_atom(key)) do
      [{_id, value}] -> value
      [] -> nil
    end
  end

  ###
  # GenServer API
  ###
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    table = :ets.new(__MODULE__, [:named_table, :public])
    File.stream!(Path.join([System.cwd(), "lib", "gt", "currency", "codes.xml"]))
    |> stream_tags([:CcyNtry])
    |> Stream.map(fn {_, doc} ->
      case [xpath(doc, ~x"./CcyNbr/text()"), xpath(doc, ~x"./Ccy/text()")] do
        [nil, _] -> nil
        [_, nil] -> nil
        [code, currency] -> [(code), currency] |> Enum.map(&to_string/1)
      end
    end)
    |> Enum.map(fn
      nil -> nil
      [code, currency] -> save(code, currency)
    end)
    {:ok, table}
  end
end
