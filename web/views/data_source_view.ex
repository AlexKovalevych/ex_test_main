defmodule Gt.DataSourceView do
  use Gt.Web, :view

  def pomadorro_types() do
    Gt.DataSource.pomadorro_types()
  end

  def rates_types() do
    Gt.DataSource.rates_types()
  end

  def is_started(data_source) do
    Gt.DataSource.is_started(data_source)
  end

  def separators() do
    Gt.DataSource.separators()
    |> Enum.map(&{translate_separator(&1), &1})
  end

  def double_qoutes() do
    Gt.DataSource.double_qoutes()
    |> Enum.map(&{translate_double_qoutes(&1), &1})
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
