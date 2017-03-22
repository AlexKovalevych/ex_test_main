defmodule Gt.PaymentCheckSourceValue do
  @enforce_keys [:value, :currency]
  defstruct [:value, :currency, :alternatives]
end

defmodule Gt.PaymentCheckSourceReport do
  use Gt.Web, :model

  schema "payment_check_source_reports" do
    field :filename, :string
    field :merchant, :string
    field :error, :string
    field :from, :date
    field :to, :date
    field :currency, :string
    field :extra_data, :map

    field :in, :map
    field :out, :map
    field :fee_in, :map
    field :fee_out, :map
    field :chargeback, :map
    field :representment, :map

    belongs_to :payment_check, Gt.PaymentCheck

    timestamps()
  end

  @required_fields ~w(filename payment_check_id)a

  @optional_fields ~w(error merchant from to currency extra_data in out fee_in fee_out chargeback representment)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
