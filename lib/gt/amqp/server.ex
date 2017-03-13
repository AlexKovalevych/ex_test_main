defmodule Gt.Amqp.Server do
  use Supervisor
  require Logger

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(:ok) do
    Application.get_env(:gt, :amqp).connections
    |> Enum.map(fn {k, url} ->
      producers = Application.get_env(:gt, :amqp).producers |> connection_workers(k)
      consumers = Application.get_env(:gt, :amqp).consumers |> connection_workers(k)
      name = "gt_amqp_#{k}" |> String.to_atom()
      worker(Gt.Amqp.Connection,
             [%{url: url, producers: producers, consumers: consumers}, [name: name]],
             restart: :permanent,
             id: name)
    end)
    |> supervise(strategy: :one_for_one)
  end

  defp connection_workers(config, connection) do
    config
    |> Enum.filter(fn {_, %{connection: conn}} -> connection == conn end)
    |> Enum.into(%{})
  end

end
