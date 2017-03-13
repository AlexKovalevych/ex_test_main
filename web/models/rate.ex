defmodule Gt.Rate do
  use Gt.Web, :model

  schema "abstract table: rates" do
    field :date, :date
    field :currency, :string
    field :rate, :float
  end

  @required_fields ~w(date currency rate)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end

  def xe() do
    from(r in {"xe_rates", __MODULE__})
  end

  def cbr() do
    from(r in {"cbr_rates", __MODULE__})
  end

  def ecb() do
    from(r in {"ecb_rates", __MODULE__})
  end

  def by_currency_date(query, currency, date) do
    query |> where([r], r.currency == ^currency and r.date == ^date)
  end

end
