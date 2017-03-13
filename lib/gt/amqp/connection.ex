defmodule Gt.Amqp.Connection do
  use GenServer
  use AMQP
  require Logger

  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def init(state) do
    Logger.metadata(channel: :amqp)
    reconnect(state)
  end

  def handle_call({:send, producer, message}, _from, %{producers: producers, channel: channel} = state) do
    config = Map.get(producers, producer)
    {:reply, Basic.publish(channel, config.exchange, config.routing, message), state}
  end

  defp reconnect(%{url: url, producers: producers, consumers: consumers} = state) do
    case Connection.open(url) do
      {:ok, conn} ->
        # Get notifications when the connection goes down
        Process.monitor(conn.pid)
        # Everything else remains the same
        {:ok, channel} = Channel.open(conn)
        Basic.qos(channel, prefetch_count: 10)

        # create required exchanges and queues
        Enum.each(producers, fn {_, %{exchange: exchange, queue: queue}} ->
          Queue.declare(channel, queue, durable: true)
          Exchange.direct(channel, exchange, durable: true)
          Queue.bind(channel, queue, exchange)
        end)

        consumer_tags = consumers
                        |> Enum.map(fn {_, %{exchange: exchange, queue: queue, routing: routing, callback: callback}} ->
                          Queue.declare(channel, queue,
                                        durable: true,
                                        arguments: [{"x-dead-letter-exchange", :longstr, ""},
                                                    {"x-dead-letter-routing-key", :longstr, "#{queue}_error"}])
                          Exchange.direct(channel, exchange, durable: true)
                          Queue.bind(channel, queue, exchange, routing_key: routing)
                          # Register the GenServer process as a consumer
                          {:ok, consumer_tag} = Basic.consume(channel, queue)
                          {consumer_tag, callback}
                        end)
                        |> Enum.into(%{})
        Logger.info("Opened connection to #{url}")
        state = Map.put(state, :consumers, consumer_tags)
        {:ok, Map.put(state, :channel, channel)}
      {:error, reason} ->
        Logger.error("Could not open connection to #{url}. Reason: #{reason}")
        # Reconnection loop
        :timer.sleep(5000)
        reconnect(state)
    end
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, state) do
    {:ok, chan} = reconnect(state)
    {:noreply, chan}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: _consumer_tag}}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: _consumer_tag}}, state) do
    {:noreply, state}
  end

  def handle_info({:basic_deliver, payload, data}, state) do
    %{consumer_tag: consumer_tag, delivery_tag: tag, redelivered: redelivered} = data
    case Map.get(state.consumers, consumer_tag) do
      nil ->
        Basic.reject state.channel, tag, requeue: false
        Logger.error("Message #{payload} was rejected for routing_key: #{data.routing_key}")
      callback ->
        spawn fn -> apply(callback, :execute, [state.channel, tag, redelivered, payload]) end
    end
    {:noreply, state}
  end

end
