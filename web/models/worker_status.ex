defmodule Gt.WorkerStatus do
  use Ecto.Schema
  import Ecto.Changeset
  import Gt.Gettext

  embedded_schema do
    field :state, :string
    field :text, :string, default: ""
  end

  defimpl Poison.Encoder, for: __MODULE__ do
    def encode(%{state: state, text: text}, options) do
      status = case state do
        "normal" -> %{state: "success", text: gettext "process_completed"}
        "stopped" -> %{state: "warning", text: gettext "worker_stopped"}
        _ -> %{state: "danger", text: to_string(text)}
      end

      Poison.encode!(status, options)
    end
  end

  @required_fields ~w(state text)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

end

defimpl Phoenix.HTML.Safe, for: Gt.WorkerStatus do
  def to_iodata(%Gt.WorkerStatus{state: state}) do
    Plug.HTML.html_escape(state)
  end
end
