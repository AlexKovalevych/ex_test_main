defmodule Gt.Api.Wl.EapiGame do
  @derive [Poison.Encoder]

  defstruct [:round, :user_id, :game_id, :bet, :win, :startTime, :chances]
end
