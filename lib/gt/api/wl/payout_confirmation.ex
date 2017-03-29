defmodule Gt.Api.Wl.PayoutConfirmation do
  @derive [Poison.Encoder]

  defstruct [status: 1, emitter: nil]
end
