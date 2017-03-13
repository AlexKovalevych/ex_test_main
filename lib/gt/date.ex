defmodule Gt.Date do
  use Timex
  import Gt.Gettext

  @date_format "%Y-%m-%d"
  @month_format "%Y-%m"
  @time_format "%H-%M-%S"
  @datetime_format "%Y-%m-%d %H:%M:%S"
  @gt_datetime_no_sec_format "%Y-%m-%d %H:%M"

  def translate(date, :date) do
    month = date
            |> Timex.format!("{M}")
            |> String.to_integer
            |> month_to_name
    date |> Timex.format!("{D} #{month}, {YYYY}")
  end

  def translate(date, :month) do
    month = date
            |> Timex.format!("{M}")
            |> String.to_integer
            |> month_to_name
    date |> Timex.format!("#{month} {YYYY}")
  end

  def month_to_name(month) do
    case month do
      1 -> gettext "jan"
      2 -> gettext "feb"
      3 -> gettext "mar"
      4 -> gettext "apr"
      5 -> gettext "may"
      6 -> gettext "jun"
      7 -> gettext "jul"
      8 -> gettext "aug"
      9 -> gettext "sep"
      10 -> gettext "oct"
      11 -> gettext "nov"
      12 -> gettext "dec"
    end
  end

  def format(nil, _), do: nil

  def format(date, _) when is_bitstring(date) do
    date
  end

  def format(date, :date) do
    Timex.format!(date, @date_format, :strftime)
  end

  def format(date, :time) do
    Timex.format!(date, @time_format, :strftime)
  end

  def format(date, :month) do
    Timex.format!(date, @month_format, :strftime)
  end

  def format(date, :datetime) do
    Timex.format!(date, @datetime_format, :strftime)
  end

  def format(date, :gt_datetime_no_sec) do
    Timex.format!(date, @gt_datetime_no_sec_format, :strftime)
  end

  def diff(start_date, end_date, :days) do
    Timex.diff(start_date, end_date, :days)
  end

  def parse(date, :date) do
    [year, month, day] = String.split(date, "-") |> Enum.map(&String.to_integer/1)
    Timex.today |> Timex.set([year: year, month: month, day: day])
  end

end

defimpl Poison.Encoder, for: Tuple do
  def encode(value, options) do
    Poison.Encoder.BitString.encode(inspect(value), options)
  end
end
