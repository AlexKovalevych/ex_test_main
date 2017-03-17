defmodule Gt.Pdf.Parser do
  use GenServer
  use Export.Python
  require Logger

  def start_link(opts) do
    {:ok, pid} = :python.start(opts)
    GenServer.start_link(__MODULE__, pid, name: __MODULE__)
  end

  def handle_call({:parse, path}, _from, pid) do
    try do
      res = Python.call(pid, "parser", "parse", [path])
      {:reply, res, pid}
    catch
      x ->
        Logger.error(x)
        {:reply, nil, pid}
    rescue
      _ -> {:reply, nil, pid}
    end
  end
end
