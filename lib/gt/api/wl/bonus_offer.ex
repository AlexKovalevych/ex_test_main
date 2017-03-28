defmodule Gt.Api.Wl.BonusOffer do
  @derive [Poison.Encoder]

  defstruct [:id, :created_at, :author, :item]
end
