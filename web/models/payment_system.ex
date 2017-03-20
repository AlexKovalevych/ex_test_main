defmodule Gt.PaymentSystem do
  use Gt.Web, :model

  schema "payment_systems" do
    field :name, :string
    embeds_one :fields, Gt.PaymentSystemFields, on_replace: :delete
    embeds_one :csv, Gt.PaymentSystemCsv, on_replace: :delete
    embeds_one :one_gamepay, Gt.PaymentSystemOneGamepay, on_replace: :delete
    embeds_one :fee, Gt.PaymentSystemFee, on_replace: :delete
    embeds_one :report, Gt.PaymentSystemReport, on_replace: :delete
    field :script, :string

    timestamps()
  end

  @scripts ~w(
    apko
    accentpay_out
    acp
    dengionline_in
    dengionline_out
    dengionline_web_in
    dengionline_web_out
    ecp
    qiwi
    skrill_ggs
    skrill_pm
    skrill_pm_a
    wirecard
    yandex_in
    yandex_out
    yandex_refund
    yandex_via_acceptance_in
    yandex_via_acceptance_out
    zimpler
  )

  def scripts(), do: @scripts

  @required_fields ~w(name)a

  @optional_fields ~w(script)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:script, @scripts)
    |> cast_embed(:fields, required: true)
    |> cast_embed(:csv)
    |> cast_embed(:one_gamepay)
    |> cast_embed(:fee)
    |> cast_embed(:report)
  end

  def options(query \\ __MODULE__) do
    query
    |> order_by_name
    |> Repo.all
    |> Enum.into(%{}, fn payment_system -> {payment_system.name, payment_system.id} end)
  end

  def order_by_name(query) do
    query |> order_by([ps], fragment("? collate \"C\"", ps.name))
  end

end
