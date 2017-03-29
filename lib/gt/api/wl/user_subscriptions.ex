defmodule Gt.Api.Wl.UserSubscriptions do
  @derive [Poison.Encoder]

  defstruct [:user_id, :emails, :sms]
end
