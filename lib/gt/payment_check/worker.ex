defmodule Gt.PaymentCheckWorker do
  use GenServer
  alias Gt.PaymentCheck
  alias Gt.PaymentCheckRegistry
  alias Gt.PaymentCheckTransaction
  alias Gt.PaymentCheck.Processor
  alias Gt.Repo
  use Timex
  require Logger

  def send_socket(payment_check) do
    processed = PaymentCheckRegistry.find(payment_check.id, :processed)
    total = PaymentCheckRegistry.find(payment_check.id, :total)
    Gt.Endpoint.broadcast("payment_check:#{payment_check.id}",
                          "payment_check:update",
                          %{payment_check |
                            processed: processed,
                            total: total
                          })
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    GenServer.call(Gt.Monitor, {:monitor, state.payment_check})
    {:ok, state}
  end

  def handle_cast(:run, state) do
    Logger.metadata(channel: :payment_check, id: state.payment_check.id)
    Logger.info("Start worker")
    # Load data_source from db since it may be called with delay
    payment_check = Repo.get!(PaymentCheck, state.payment_check.id) |> init_worker
    Logger.info("Delete all transactions for payment check #{payment_check.id}")
    PaymentCheckTransaction
    |> PaymentCheckTransaction.by_payment_check(payment_check.id)
    |> Repo.delete_all()

    {:ok, timer} = :timer.apply_interval(500, __MODULE__, :send_socket, [payment_check])
    script = payment_check.ps["script"]
    total_files = Enum.count(payment_check.files)
    module = if script do
      Module.concat("Gt.PaymentCheck", String.capitalize(script))
    else
      Module.concat("Gt.PaymentCheck", "Processor")
    end
    module
    |> struct(%{payment_check: payment_check, total_files: total_files})
    |> Processor.run

    :timer.cancel(timer)
    Logger.info("Complete worker")
    {:stop, :normal, %{state | payment_check: complete(payment_check)}}
  end

  defp complete(payment_check) do
    payment_check
    |> PaymentCheck.changeset(%{
      active: false,
      total: PaymentCheckRegistry.find(payment_check.id, :total) || 0,
      processed: PaymentCheckRegistry.find(payment_check.id, :processed) || 0,
      skipped: PaymentCheckRegistry.find(payment_check.id, :skipped) || 0,
      completed: true,
    })
    |> Repo.update!
  end

  defp init_worker(payment_check) do
    PaymentCheckRegistry.create(payment_check.id)
    PaymentCheckRegistry.save(payment_check.id, :pid, self())
    PaymentCheckRegistry.save(payment_check.id, :processed, 0)
    PaymentCheckRegistry.save(payment_check.id, :skipped, 0)
    PaymentCheck.clear_state(payment_check)
  end

end
