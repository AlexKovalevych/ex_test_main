defmodule Gt.Api.Wl.BatchPayoutRefusal do
  @derive [Poison.Encoder]

  defstruct [:emitter, :reason, :comment]
end
