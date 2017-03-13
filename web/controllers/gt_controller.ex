defmodule Gt.Phoenix.Controller do
  defmacro __using__(opts \\ []) do
    key = Keyword.get(opts, :key, :default)
    quote do
      import Guardian.Plug
      def action(conn, _opts) do
        apply(
          __MODULE__,
          action_name(conn),
          [
            conn,
            conn.params,
            Guardian.Plug.current_resource(conn, unquote(key))
          ]
        )
      end
    end
  end
end
