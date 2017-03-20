defmodule Gt.PaymentSystemView do
  use Gt.Web, :view

  def separators() do
    Gt.PaymentSystemCsv.separators()
    |> Enum.map(&{translate_separator(&1), &1})
  end

  def double_qoutes() do
    Gt.PaymentSystemCsv.double_qoutes()
    |> Enum.map(&{translate_double_qoutes(&1), &1})
  end

  def encodings() do
    Gt.PaymentSystemCsv.encodings()
  end

  def payment_types() do
    Gt.PaymentCheckTransaction.types()
  end

  defp translate_separator(value) do
    case value do
      "comma" -> gettext "comma"
      "tab" -> gettext "tab"
      "colon" -> gettext "colon"
      "pipe" -> gettext "pipe"
      "space" -> gettext "space"
      "semicolon" -> gettext "semicolon"
    end
  end

  defp translate_double_qoutes(value) do
    case value do
      "double_qoute" -> gettext "double_qoute"
      "single_qoute" -> gettext "single_qoute"
    end
  end
end
