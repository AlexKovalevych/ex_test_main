defmodule Gt.LayoutView do
  use Gt.Web, :view

  @doc """
  verifies if menu item is active
  """
  def is_active(conn, url) do
    prefix = String.split(url, "/")
    |> Enum.take(3)
    |> Enum.join("/")
    String.starts_with?(conn.request_path, prefix)
  end

end
