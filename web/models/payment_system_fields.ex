defmodule Gt.PaymentSystemFields do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :map_id, :string
    field :date, :string
    field :sum, :string
    field :currency, :string
    field :default_payment_type, :string
    field :account_id, :string
    field :default_account_id, :string
    field :player_purse, :string
    field :type, :string
    field :state, :string
    field :state_ok, :string
    field :type_in, :string
    field :type_out, :string
    field :is_out_negative, :boolean, default: false
    field :comment, :string

    # Ecp
    field :fee_in_percent, :float
    field :fee_out_percent, :float
    field :fee_sum_rub, :float
    field :darmako_merchants, :string
    field :ggs_merchants, :string
  end

  @required_fields ~w(map_id date sum)a

  @optional_fields ~w(currency
                      default_payment_type
                      account_id
                      default_account_id
                      player_purse
                      type
                      state
                      state_ok
                      type_in
                      type_out
                      is_out_negative
                      comment
                      fee_in_percent
                      fee_out_percent
                      fee_sum_rub
                      darmako_merchants
                      ggs_merchants
                    )a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
