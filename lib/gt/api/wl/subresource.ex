defmodule Gt.Api.Wl.Subresource do
  @derive [Poison.Encoder]

  defstruct [:name, :id, :item, :verified]
end
