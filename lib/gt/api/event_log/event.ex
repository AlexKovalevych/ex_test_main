defmodule Gt.Api.EventLogEvent do
  @derive [Poison.Encoder]

  defstruct [:id, :time, :project_id, :user_id, :data, :name]
end
