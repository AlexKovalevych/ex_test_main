defmodule Gt.CalendarGroup do
  use Gt.Web, :model
  @derive {Poison.Encoder, only: [:id, :name]}

  schema "calendar_groups" do
    field :name, :string
    field :color, :string

    timestamps()
  end

  @required_fields ~w(name color)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end

defimpl Phoenix.HTML.Safe, for: Gt.CalendarGroup do
  def to_iodata(%Gt.CalendarGroup{name: name}) do
    Plug.HTML.html_escape(name)
  end
end
