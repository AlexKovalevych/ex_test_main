defmodule Gt.Api.Wl.PayoutEmitter do
  @derive [Poison.Encoder]

  defstruct [:id, :email]
end
