defmodule Gt.Api.Wl.GiftSpin do
  @derive [Poison.Encoder]

  defstruct [:code, :game, :line_stake, :line_count, :spin_count, :created_at]
end
