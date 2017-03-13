defmodule Gt.Plug.Locale do
  def init(_opts), do: nil

  def call(conn, _) do
    case conn.private do
      %{guardian_default_resource: user} when not is_nil(user) ->
        Gettext.put_locale(Gt.Gettext, user.locale)
      _ ->
        conn
    end
    conn
  end
end
