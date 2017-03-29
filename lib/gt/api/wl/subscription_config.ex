defmodule Gt.Api.Wl.SubscriptionConfig do
  @derive [Poison.Encoder]

  defstruct [:emails, :sms]
end
