defmodule Gt.Api.Wl.LevelCompoints do
  @derive [Poison.Encoder]

  defstruct [:id, :level, :wager, :rates]
end
