defmodule Gt.DataSourceServer do
  use Supervisor
  alias Gt.DataSourceRegistry
  alias Gt.DataSource
  import Ecto.Query
  alias Gt.Repo
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(:ok) do
    children = [
      worker(Gt.DataSourceWorker, [], restart: :temporary, shutdown: 500)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  @doc """
  Resume incompleted cron workers
  """
  def continue_workers() do
    DataSource
    |> where([c], c.interval > 0 and c.completed == false)
    |> Repo.all
    |> Enum.map(fn data_source ->
      case add_worker(data_source) do
        {:ok, pid} -> GenServer.cast(pid, String.to_atom(data_source.type))
        {:error, _reason} -> Logger.error("Couldn't continue data_source worker #{data_source.id}")
      end
    end)
  end

  def add_worker(data_source) do
    Supervisor.start_child(__MODULE__, [%{data_source: data_source}])
  end

  def stop_worker(data_source) do
    res = case DataSourceRegistry.find(data_source.id, :pid) do
      nil -> :ok
      pid -> Supervisor.terminate_child(__MODULE__, pid)
    end
    data_source = data_source
    |> DataSource.changeset(%{active: false})
    |> Ecto.Changeset.put_embed(:status, %Gt.WorkerStatus{state: "stopped"})
    |> Repo.update!
    Gt.Endpoint.broadcast("data_source:#{data_source.id}", "data_source:update", data_source)
    DataSourceRegistry.delete(data_source.id)
    res
  end

end
