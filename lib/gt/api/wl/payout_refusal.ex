defmodule Gt.Api.Wl.PayoutRefusal do
  @derive [Poison.Encoder]

  defstruct [status: 2, emitter: nil, reason: nil, comment: nil]
end
