defmodule Gt.CacheServer do
  use Supervisor
  alias Gt.CacheRegistry
  alias Gt.Cache
  import Ecto.Query
  alias Gt.Repo
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(:ok) do
    children = [
      worker(Gt.CacheWorker, [], restart: :temporary, shutdown: 500)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  @doc """
  Resume incompleted cron workers
  """
  def continue_workers() do
    Cache
    |> where([c], c.interval > 0 and c.completed == false)
    |> Repo.all
    |> Enum.map(fn cache ->
      case add_worker(cache) do
        {:ok, pid} -> GenServer.cast(pid, String.to_atom(cache.type))
        {:error, _reason} -> Logger.error("Couldn't continue cache worker #{cache.id}")
      end
    end)
  end

  def add_worker(cache) do
    Supervisor.start_child(__MODULE__, [%{cache: cache}])
  end

  def stop_worker(cache) do
    res = case CacheRegistry.find(cache.id, :pid) do
      nil -> :ok
      pid -> Supervisor.terminate_child(__MODULE__, pid)
    end
    cache = cache
    |> Cache.changeset(%{active: false})
    |> Ecto.Changeset.put_embed(:status, %Gt.WorkerStatus{state: "stopped"})
    |> Repo.update!
    Gt.Endpoint.broadcast("cache:#{cache.id}", "cache:update", cache)
    CacheRegistry.delete(cache.id)
    res
  end

end
