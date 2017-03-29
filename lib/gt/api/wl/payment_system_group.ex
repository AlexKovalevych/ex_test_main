defmodule Gt.Api.Wl.PaymentSystemGroup do
  @derive [Poison.Encoder]

  defstruct [:id, :title, :paymentSystems]
end
