defmodule Gt.DataSourceRegistry do
  use GenServer
  import String, only: [to_atom: 1]

  def create(id) do
    :ets.new(get_key(id), [:named_table, :public])
  end

  def save(id, key, value) do
    :ets.insert(get_key(id), {key, value})
  end

  def increment(id, key, value \\ 1) do
    :ets.update_counter(get_key(id), key, {2, value})
  end

  def delete(id, key) do
    :ets.delete(get_key(id), key)
  end

  def delete(id) do
    try do
      :ets.delete(get_key(id))
    rescue
      _ in ArgumentError -> nil
    end
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
    "data_source_#{id |> to_string}" |> to_atom
  end

  def handle_call({:new_user_stats, {user, date}, data_source_id}, _from, state) do
    case find(data_source_id, :new_user_stats) do
      nil -> save(data_source_id, :new_user_stats, Map.put(%{}, user.id, {user, date, date, 1}))
      value ->
        new_value = case Map.get(find(data_source_id, :new_user_stats), user.id) do
          nil ->
            {user, date, date, 1}
          {user, from, to, count} ->
            from = if Timex.compare(date, from) == -1, do: date, else: from
            to = if Timex.compare(date, to) == 1, do: date, else: to
            {user, from, to, count + 1}
        end
        save(data_source_id, :new_user_stats, Map.put(value, user.id, new_value))
    end
    {:reply, nil, state}
  end

end
