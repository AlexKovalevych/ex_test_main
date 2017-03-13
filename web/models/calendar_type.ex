defmodule Gt.CalendarType do
  use Gt.Web, :model

  schema "calendar_types" do
    field :name, :string
    belongs_to :group, Gt.CalendarGroup

    timestamps()
  end

  @required_fields ~w(name group_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

  def options(query \\ __MODULE__) do
    query
    |> order_by([ct], fragment("? collate \"C\"", ct.name))
    |> Repo.all
    |> Enum.map(fn type -> {type.name, type.id} end)
  end
end

defimpl Phoenix.HTML.Safe, for: Gt.CalendarType do
  def to_iodata(%Gt.CalendarType{name: name}) do
    Plug.HTML.html_escape(name)
  end
end
