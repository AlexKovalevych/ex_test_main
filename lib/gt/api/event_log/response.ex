defmodule Gt.Api.EventLogResponse do
  @derive [Poison.Encoder]

  defstruct [:status, :requestTime, :eventsCount, :events]
end
