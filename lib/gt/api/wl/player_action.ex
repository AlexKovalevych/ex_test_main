defmodule Gt.Api.Wl.PlayerAction do
  @derive [Poison.Encoder]

  defstruct [:created_at, :ip, :user_agent, :action, :comment]
end
