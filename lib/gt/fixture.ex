defmodule Gt.Fixture do

  defmacro run(module) do
    quote do
      module = unquote module
      Logger.info("Loading #{module} fixtures")
      apply(module, :run, [])
      Logger.info("Loaded #{module} fixtures")
    end
  end

end
