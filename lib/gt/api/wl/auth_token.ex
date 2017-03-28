defmodule Gt.Api.Wl.AuthToken do
  @derive [Poison.Encoder]

  defstruct [:user_id, :token]
end
