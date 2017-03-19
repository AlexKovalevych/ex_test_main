defmodule Gt.Monitor do
  use GenServer
  alias Gt.PaymentCheck
  alias Gt.Repo
  alias Gt.PaymentCheckRegistry
  alias Gt.WorkerStatus

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def handle_call({:monitor, struct}, {pid, _}, state) do
    ref = Process.monitor(pid)
    {:reply, :ok, state |> Map.put(ref, struct)}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    new_state = case Map.get(state, ref) do
      nil -> state
      struct ->
        terminate_worker(reason, struct)
        Map.delete(state, ref)
    end
    {:noreply, new_state}
  end

  def terminate_worker(%WorkerStatus{} = status, %PaymentCheck{id: id}) do
    case Repo.get(PaymentCheck, id) do
      nil ->
        PaymentCheckRegistry.delete(id)
      payment_check ->
        payment_check
        |> PaymentCheck.changeset(%{active: false})
        |> Ecto.Changeset.put_embed(:status, status)
        |> Repo.update!
        PaymentCheckRegistry.delete(id)
        Gt.Endpoint.broadcast("payment_check:#{id}", "payment_check:update", payment_check)
    end
  end

  def terminate_worker(:normal, struct) do
    %WorkerStatus{state: ":normal"} |> terminate_worker(struct)
  end

  def terminate_worker(reason, %PaymentCheck{id: id} = payment_check) do
    PaymentCheckRegistry.delete(id)
    %WorkerStatus{state: "danger", text: inspect(reason, pretty: true, width: 0) |> String.replace("\n", "<br>")}
    |> terminate_worker(payment_check)
  end

end
