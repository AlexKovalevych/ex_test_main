defmodule Gt.Api.Wl.WalletEvent do
  @derive [Poison.Encoder]

  defstruct [:emitter_id, :type, :data]
end
