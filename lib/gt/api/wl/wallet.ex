defmodule Gt.Api.Wl.Wallet do
  @derive [Poison.Encoder]

  defstruct [:wallet_version, :created_at, :event]
end
