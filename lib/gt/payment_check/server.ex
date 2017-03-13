defmodule Gt.PaymentCheckServer do
  use Supervisor
  alias Gt.PaymentCheckRegistry
  alias Gt.PaymentCheck
  import Ecto.Query
  alias Gt.Repo
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(:ok) do
    children = [
      worker(Gt.PaymentCheckWorker, [], restart: :temporary, shutdown: 500)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  @doc """
  Resume incompleted cron workers
  """
  def continue_workers() do
    PaymentCheck
    |> where([pc], pc.active == true and pc.completed == false)
    |> Repo.all
    |> Enum.map(fn payment_check ->
      case add_worker(payment_check) do
        {:ok, pid} -> GenServer.cast(pid, :run)
        {:error, _reason} -> Logger.error("Couldn't continue payment_check worker #{payment_check.id}")
      end
    end)
  end

  def add_worker(payment_check) do
    Supervisor.start_child(__MODULE__, [%{payment_check: payment_check}])
  end

  def stop_worker(payment_check) do
    res = case PaymentCheckRegistry.find(payment_check.id, :pid) do
      nil -> :ok
      pid -> Supervisor.terminate_child(__MODULE__, pid)
    end
    payment_check = payment_check
    |> PaymentCheck.changeset(%{active: false})
    |> Ecto.Changeset.put_embed(:status, %Gt.WorkerStatus{state: "stopped"})
    |> Repo.update!
    Gt.Endpoint.broadcast("payment_check:#{payment_check.id}", "payment_check:update", payment_check)
    PaymentCheckRegistry.delete(payment_check.id)
    res
  end

end
