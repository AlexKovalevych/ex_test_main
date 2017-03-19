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

    embeds_many :in, Gt.PaymentCheckSourceValue
    embeds_many :out, Gt.PaymentCheckSourceValue
    embeds_many :fee_in, Gt.PaymentCheckSourceValue
    embeds_many :fee_out, Gt.PaymentCheckSourceValue
    embeds_many :chargeback, Gt.PaymentCheckSourceValue
    embeds_many :representment, Gt.PaymentCheckSourceValue

    belongs_to :payment_check, Gt.PaymentCheck

    timestamps()
  end

  @required_fields ~w(filename merchant from to currency payment_check_id)a

  @optional_fields ~w(error extra_data)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
