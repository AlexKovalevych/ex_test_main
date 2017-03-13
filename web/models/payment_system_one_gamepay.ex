defmodule Gt.PaymentSystemOneGamepay do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :map_id, :string
    field :payment_system, :string
  end

  @required_fields ~w()a

  @optional_fields ~w(map_id payment_system)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
