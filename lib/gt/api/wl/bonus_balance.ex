defmodule Gt.Api.Wl.BonusBalance do
  @derive [Poison.Encoder]

  defstruct [:amount, :wager, :user_id, :mustPlay, :enable_bonuses, :enabled_bonuses_coupons, :remain_play]
end
