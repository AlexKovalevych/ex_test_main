defmodule Gt.DataSource.GsWlRest do
  alias Gt.Repo
  alias Gt.Project
  alias Gt.DataSourceRegistry
  alias Gt.GameServerTransaction
  alias Gt.Api.Wl.Transaction
  alias Gt.Api.WlRest
  alias Gt.Api.Wl.FilterQuery
  use Timex
  require Logger

  @limit 500

  def process_api(data_source) do
    start_at = data_source.start_at |> Timex.to_datetime
    end_at = data_source.end_at |> Timex.to_datetime |> Timex.end_of_day
    struct = %WlRest{
      url: data_source.host,
      client: data_source.client,
      key: data_source.private_key,
      filter: %FilterQuery{
        filters: %{
          created_at: %{
            ">=" => start_at |> Timex.to_unix,
            "<=" => end_at |> Timex.to_unix
          }
        },
        limit: @limit
      }
    }

    ~w(get_deposits get_payouts get_refunds)a
    |> Enum.with_index
    |> Enum.each(fn {func, index} ->
      load_transactions(data_source, func, struct, index, 0)
    end)
  end

  def load_transactions(data_source, func, struct, index, offset) do
    filter = Map.put(struct.filter, :offset, offset)
    struct = %{struct | filter: filter}
    case apply(WlRest, func, [struct]) do
      {:error, response} -> Logger.error(response)
      {:ok, %{transactions: transactions, total: count}} ->
        DataSourceRegistry.save(data_source.id, :total, count * 3)
        DataSourceRegistry.save(data_source.id, :processed, index * count)
        process_data(transactions, data_source)
        if Enum.count(transactions) < @limit, do: load_transactions(data_source, func, struct, index, offset + @limit)
    end
  end

  def process_file(data_source, {filename, index}, total_files) do
    transactions = Gt.Uploaders.DataSource.local_path(data_source.id, filename)
    |> File.read!()
    |> Poison.decode!(as: [%Transaction{}])
    count = Enum.count(transactions)
    DataSourceRegistry.save(data_source.id, :total, total_files * count)
    DataSourceRegistry.save(data_source.id, :processed, index * count)
    process_data(transactions, data_source)
  end

  defp process_data(transactions, data_source) do
    transactions
    |> ParallelStream.each(&upsert_transaction(&1, data_source))
    |> Enum.reduce(0, fn _, acc -> acc + 1 end)
  end

  defp upsert_transaction(data, data_source) do
    date = Timex.from_unix(data.created_at)
    fields = %{
      date: date,
      user_sum: data.sum,
      system_id: data.payment_system,
      status: data.status,
      pguid: data.external_id,
    }

    transaction = %GameServerTransaction{}
    |> GameServerTransaction.changeset(Map.merge(
      fields,
      %{
        item_id: data.id,
        project_id: data_source.project.id
      }
    ))

    on_conflict = [set: Map.to_list(fields)]
    Repo.insert!(transaction, on_conflict: on_conflict, conflict_target: [:item_id, :project_id])
    DataSourceRegistry.increment(data_source.id, :processed)
  end

end
