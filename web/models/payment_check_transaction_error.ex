defmodule Gt.PaymentCheckTransactionError do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :type
    field :message
  end

  @type_1gp "1gp"
  @type_gameserver "gameserver"

  def type(:"1gp"), do: @type_1gp
  def type(:"gameserver"), do: @type_gameserver

  def types(), do: [@type_1gp, @type_gameserver]

  @error_not_found "not_found"
  @error_duplicate "duplicate"
  @error_invalid_sum "invalid_sum"
  @error_invalid_currency "invalid_currency"
  @error_invalid_date "invalid_date"

  def message(:not_found), do: @error_not_found
  def message(:duplicate), do: @error_duplicate
  def message(:invalid_sum), do: @error_invalid_sum
  def message(:invalid_currency), do: @error_invalid_currency
  def message(:invalid_date), do: @error_invalid_date

  def messages(), do: [
    @error_not_found,
    @error_duplicate,
    @error_invalid_sum,
    @error_invalid_currency,
    @error_invalid_date
  ]

  @required_fields ~w(type message)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, types())
    |> validate_inclusion(:message, messages())
  end

end
