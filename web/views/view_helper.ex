defmodule Gt.ViewHelpers do
  use Phoenix.HTML
  import Gt.Gettext

  def phone(value) do
    {a, b} = String.split_at(value, -6)
    {_, c} = String.split_at(b, -2)
    a <> "****" <> c
  end

  def paginate(conn, paginator, opts \\ []) do
    opts = Keyword.merge(opts,
                         next_label: gettext("next"),
                         previous_label: gettext("previous"),
                         first_label: 1,
                         last_label: paginator.total_pages,
                         window: 10
                       )
    Kerosene.HTML.paginate(conn, paginator, opts)
  end

end
