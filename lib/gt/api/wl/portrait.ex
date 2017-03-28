defmodule Gt.Api.Wl.Portrait do
  @derive [Poison.Encoder]

  defstruct [:id, :created_at, :author, :item]
end
