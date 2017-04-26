defmodule Gt.Api.EventLogEvent do
  @derive [Poison.Encoder]

  # TODO This can be improved in custom defimpl function for decoding JSON
  defstruct [:id, :event_id, :time, :project_id, :user_id, :userid, :data, :name]

  def get_id(%__MODULE__{} = event) do
    Map.get(event, :id, Map.get(event, :event_id))
  end
end
