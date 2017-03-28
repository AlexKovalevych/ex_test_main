defmodule Gt.Api.Wl.Comment do
  @derive [Poison.Encoder]

  defstruct [:id, :created_at, :author, :item]
end
