defmodule Gt.PaymentSystemFee do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :map_id, :string
    field :currency, :string
    field :sum, :float
    field :percent, :float
    field :max_fee, :float
    field :default_account_id, :string
    field :fee_report, :boolean # Defines fee source
    field :divide_100, :boolean # Defines need to divide sum and fee by 100
    field :types, {:array, :string}, default: []
  end

  @required_fields ~w()a

  @optional_fields ~w(map_id
                      currency
                      sum
                      percent
                      default_account_id
                      max_fee
                      fee_report
                      divide_100
                      types
                    )a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_subset(:types, Gt.PaymentCheckTransaction.types())
  end
end
