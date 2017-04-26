defmodule Gt.DataSourceWorker do
  use GenServer
  alias Gt.DataSource
  alias Gt.DataSourceRegistry
  alias Gt.Repo
  use Timex
  require Logger

  def send_socket(data_source) do
    processed = DataSourceRegistry.find(data_source.id, :processed)
    total = DataSourceRegistry.find(data_source.id, :total)
    Gt.Endpoint.broadcast("data_source:#{data_source.id}", "data_source:update", %{data_source | processed: processed, total: total})
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    GenServer.call(Gt.Monitor, {:monitor, state.data_source})
    {:ok, state}
  end

  def handle_cast(:rates, state) do
    Logger.metadata(channel: :data_source_rates, id: state.data_source.id)
    Logger.info("Start worker")
    # Load data_source from db since it may be called with delay
    data_source = Repo.get!(DataSource, state.data_source.id) |> init_worker

    {:ok, timer} = :timer.apply_interval(500, __MODULE__, :send_socket, [data_source])
    case Enum.empty?(data_source.files) do
      false ->
        DataSourceRegistry.save(data_source.id, :total, Enum.count(data_source.files))
        data_source.files |> Enum.map(&Gt.DataSource.Rates.process_file(data_source, &1))
      true ->
        start_at = data_source.start_at |> Timex.format!("{ISOdate}")
        end_at = data_source.end_at |> Timex.format!("{ISOdate}")
        period = "[#{start_at}|#{end_at}]"
        Logger.metadata(period: period)
        Gt.DataSource.Rates.process_api(data_source)
    end

    :timer.cancel(timer)
    Logger.info("Complete worker")
    if data_source.interval do
      data_source = complete(data_source, new_period(data_source))
      Process.send_after(self(), {:"$gen_cast", :rates}, data_source.interval * 60 * 1000)
      {:noreply, %{cache: data_source}}
    else
      {:stop, :normal, %{state | data_source: complete(data_source)}}
    end
  end

  def handle_cast(:event_log, state) do
    Logger.metadata(channel: :event_log, id: state.data_source.id)
    Logger.info("Start worker")

    # Load data_source from db since it may be called with delay
    data_source = Repo.get!(DataSource, state.data_source.id)
                  |> Repo.preload(:project)
                  |> init_worker

    {:ok, timer} = :timer.apply_interval(500, __MODULE__, :send_socket, [data_source])
    case Enum.empty?(data_source.files) do
      false ->
        data_source.files
        |> Enum.with_index
        |> Enum.map(&Gt.DataSource.EventLog.process_file(data_source, &1, Enum.count(data_source.files)))
      true ->
        Gt.DataSource.EventLog.process_api(data_source)
    end

    :timer.cancel(timer)
    Logger.info("Complete worker")
    if data_source.interval do
      data_source = complete(data_source, new_period(data_source))
      Process.send_after(self(), {:"$gen_cast", :event_log}, data_source.interval * 60 * 1000)
      {:noreply, %{cache: data_source}}
    else
      {:stop, :normal, %{state | data_source: complete(data_source)}}
    end
  end

  def handle_cast(:pomadorro, state) do
    Logger.metadata(channel: :data_source_pomadorro, id: state.data_source.id)
    Logger.info("Start worker")
    # Load data_source from db since it may be called with delay
    data_source = Repo.get!(DataSource, state.data_source.id)
                  |> Repo.preload(:project)
                  |> init_worker

    {:ok, timer} = :timer.apply_interval(500, __MODULE__, :send_socket, [data_source])
    case Enum.empty?(data_source.files) do
      false ->
        data_source.files
        |> Enum.with_index
        |> Enum.map(&Gt.DataSource.Pomadorro.process_file(data_source, &1, Enum.count(data_source.files)))
      true ->
        period = "[#{data_source.start_at |> Timex.format!("{ISOdate}")}|#{data_source.end_at |> Timex.format!("{ISOdate}")}]"
        Logger.metadata(period: period)
        Gt.DataSource.Pomadorro.process_api(data_source)
    end

    :timer.cancel(timer)
    Logger.info("Complete worker")
    if data_source.interval do
      data_source = complete(data_source, new_period(data_source))
      Process.send_after(self(), {:"$gen_cast", :pomadorro}, data_source.interval * 60 * 1000)
      {:noreply, %{cache: data_source}}
    else
      {:stop, :normal, %{state | data_source: complete(data_source)}}
    end
  end

  def handle_cast(:one_gamepay_request, state) do
    Logger.metadata(channel: :data_source_1gp_request, id: state.data_source.id)
    Logger.info("Start worker")
    data_source = Repo.get!(DataSource, state.data_source.id) |> init_worker

    {:ok, timer} = :timer.apply_interval(500, __MODULE__, :send_socket, [data_source])
    DataSourceRegistry.save(data_source.id, :total, Enum.count(data_source.subtypes))
    Gt.DataSource.OneGamepayRequest.process_api(data_source)

    :timer.cancel(timer)
    Logger.info("Complete worker")
    if data_source.interval do
      data_source = complete(data_source, new_period(data_source))
      Process.send_after(self(), {:"$gen_cast", :rates}, data_source.interval * 60 * 1000)
      {:noreply, %{cache: data_source}}
    else
      {:stop, :normal, %{state | data_source: complete(data_source)}}
    end
  end

  def handle_cast(:one_gamepay, state) do
    Logger.metadata(channel: :data_source_1gp, id: state.data_source.id)
    Logger.info("Start worker")
    data_source = Repo.get!(DataSource, state.data_source.id) |> init_worker

    {:ok, timer} = :timer.apply_interval(500, __MODULE__, :send_socket, [data_source])
    case Enum.empty?(data_source.files) do
      false ->
        data_source.files
        |> Enum.with_index
        |> Enum.map(&Gt.DataSource.OneGamepay.process_file(data_source, &1, Enum.count(data_source.files)))
      true ->
        Gt.DataSource.OneGamepay.process_api(data_source)
    end

    :timer.cancel(timer)
    Logger.info("Complete worker")
    if data_source.interval do
      data_source = complete(data_source, new_period(data_source))
      Process.send_after(self(), {:"$gen_cast", :rates}, data_source.interval * 60 * 1000)
      {:noreply, %{cache: data_source}}
    else
      {:stop, :normal, %{state | data_source: complete(data_source)}}
    end
  end

  def handle_cast(:gs_adm_service, state) do
    Logger.metadata(channel: :game_server, id: state.data_source.id)
    Logger.info("Start worker")
    data_source = Repo.get!(DataSource, state.data_source.id) |> init_worker

    {:ok, timer} = :timer.apply_interval(500, __MODULE__, :send_socket, [data_source])
    case Enum.empty?(data_source.files) do
      false ->
        data_source.files
        |> Enum.with_index
        |> Enum.map(&Gt.DataSource.GsAdmService.process_file(data_source, &1, Enum.count(data_source.files)))
      true ->
        Gt.DataSource.GsAdmService.process_api(data_source)
    end

    :timer.cancel(timer)
    Logger.info("Complete worker")
    if data_source.interval do
      data_source = complete(data_source, new_period(data_source))
      Process.send_after(self(), {:"$gen_cast", :rates}, data_source.interval * 60 * 1000)
      {:noreply, %{cache: data_source}}
    else
      {:stop, :normal, %{state | data_source: complete(data_source)}}
    end
  end

  defp complete(data_source, new_dates \\ nil) do
    {from, to} = case new_dates do
      nil -> {data_source.start_at, data_source.end_at}
      {from, to} -> {from, to}
    end
    data_source = data_source
    |> DataSource.changeset(%{
      active: false,
      total: DataSourceRegistry.find(data_source.id, :total) || 0,
      processed: DataSourceRegistry.find(data_source.id, :processed) || 0,
      completed: true,
      start_at: from,
      end_at: to,
    })
    if new_dates do
      %Gt.WorkerStatus{state: ":normal"} |> update_status(%{data_source: Repo.update!(data_source)})
    else
      data_source |> Repo.update!
    end
  end

  def update_status(%Gt.WorkerStatus{} = status, state) do
    data_source = state.data_source
    data_source = data_source
    |> DataSource.changeset(%{active: false})
    |> Ecto.Changeset.put_embed(:status, status)
    |> Repo.update!
    DataSourceRegistry.delete(data_source.id)
    Gt.Endpoint.broadcast("data_source:#{data_source.id}", "data_source:update", data_source)
    data_source
  end

  defp init_worker(data_source) do
    DataSourceRegistry.create(data_source.id)
    DataSourceRegistry.save(data_source.id, :pid, self())
    DataSourceRegistry.save(data_source.id, :processed, 0)
    DataSource.clear_state(data_source)
  end

  defp new_period(data_source) do
    from = data_source.start_at
    to = data_source.end_at
    today = Timex.today
    yesterday = today |> Timex.shift(days: -1)
    new_from = Timex.shift(to, days: 1)
    new_from = if Timex.compare(new_from, yesterday) >= 0, do: yesterday, else: new_from
    new_to = Timex.shift(new_from, days: Timex.diff(to, from, :days))
    new_to = if Timex.compare(new_to, today) >= 0, do: today, else: new_to
    {new_from, new_to}
  end

end
