defmodule Gt.CacheView do
  use Gt.Web, :view

  def is_started(cache) do
    Gt.Cache.is_started(cache)
  end

end
