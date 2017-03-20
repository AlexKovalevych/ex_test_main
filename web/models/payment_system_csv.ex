defmodule Gt.PaymentSystemCsv do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :separator, :string, default: ","
    field :double_qoute, :string, default: "\""
    field :encoding, :string
  end

  @separators ~w(comma tab colon pipe space semicolon)

  @double_qoutes ~w(double_qoute single_qoute)

  @encodings ~w(utf-8 windows-1251)

  def separators(), do: @separators

  def double_qoutes(), do: @double_qoutes

  def encodings(), do: @encodings

  @required_fields ~w(separator double_qoute)a

  @optional_fields ~w(encoding)a

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end

