defmodule Gt.Plug.EnsureAuthenticated do

  require Logger
  import Plug.Conn
  import Gt.Gettext
  alias Gt.Auth.Permissions

  @doc false
  def init(opts) do
    permission = Enum.into(opts, %{}) |> Map.get(:permission)
    opts = Guardian.Plug.EnsureAuthenticated.init(Keyword.delete(opts, :permission))
    Map.put(opts, :permission, permission)
  end

  @doc false
  def call(conn, opts) do
    conn = Guardian.Plug.EnsureAuthenticated.call(conn, opts)
    case conn.assigns do
      %{guardian_failure: {:error, _reason}} ->
        conn
      _ ->
        case conn |> get_session(:two_factor) do
          true ->
            resource = conn.private.guardian_default_resource
            case resource.enabled do
              true -> check_permission(conn, opts)
              false -> handle_error(conn, {:error, dgettext("login", "user_disabled")}, opts)
            end
          _ -> handle_error(conn, {:error, dgettext("login", "not_authenticated")}, opts)
        end
    end
  end

  defp check_permission(conn, opts) do
    if has_permission(opts.permission, conn.private.guardian_default_resource) do
      conn
    else
      handle_error(conn, {:error, dgettext("login", "permision_denied")}, opts)
    end
  end

  defp handle_error(%Plug.Conn{params: params} = conn, reason, opts) do
    conn = conn |> assign(:guardian_failure, reason) |> halt
    params = Map.merge(params, %{reason: reason})
    {mod, meth} = Map.get(opts, :handler)

    apply(mod, meth, [conn, params])
  end

  defp has_permission(_, %{is_admin: true}) do
    true
  end

  defp has_permission(nil, _user) do
    true
  end

  defp has_permission(permission, user) do
    Permissions.has_any(user.permissions, to_string(permission))
  end

end
