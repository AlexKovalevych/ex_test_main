defmodule Gt.Amqp.Messages.Sms do
  @enforce_keys [:phone, :clientId, :text]
  defstruct [:phone, :clientId, :text]
end
