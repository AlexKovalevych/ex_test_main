defmodule Gt.Api.Wl.Player do
  @derive [Poison.Encoder]

  defstruct [:id, :ip]
end
