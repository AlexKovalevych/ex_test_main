defmodule Gt.PaymentCheckSourceValue do
  use Gt.Web, :model

  embedded_schema do
    field :value, :float
    field :currency, :string

    embeds_many :alternatives, __MODULE__
  end

  @required_fields ~w(value currency)

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
