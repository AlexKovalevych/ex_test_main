defmodule Gt.PaymentSystemReport do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :sum, :string
    field :currency, :string
    field :divide_100, :boolean
  end

  @required_fields ~w()a

  @optional_fields ~w(currency sum divide_100)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
