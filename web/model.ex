defmodule Gt.Model do

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, :id, autogenerate: true}
      @foreign_key_type :id
    end
  end

end

defmodule Gt.Type.DateTimeNoSec do
  use Timex

  @format "%Y-%m-%d %H:%M"

  @behaviour Ecto.Type

  def type, do: :naive_datetime

  # Provide our own casting rules.
  def cast(string) when is_binary(string) do
    case Timex.parse(string, @format, :strftime) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  def cast(%NaiveDateTime{} = datetime) do
    {:ok, datetime}
  end

  # Everything else is a failure though
  def cast(_), do: :error

  def load({{year, month, day}, {hour, min, sec, _usec}}) do
    NaiveDateTime.from_erl({{year, month, day}, {hour, min, sec}})
  end

  def dump(%NaiveDateTime{} = date) do
    {usec, _} = date.microsecond
    {date, time} = NaiveDateTime.to_erl(date)
    {:ok, {date, Tuple.append(time, usec)}}
  end
  def dump(_), do: :error
end

defmodule Gt.Type.Month do
  use Timex

  @format "%Y-%m"

  @behaviour Ecto.Type

  def type, do: :date

  # Provide our own casting rules.
  def cast(string) when is_binary(string) do
    case Timex.parse(string, @format, :strftime) do
      {:ok, result} -> {:ok, result |> Timex.to_date()}
      _ -> :error
    end
  end

  def cast(%Date{} = date) do
    {:ok, date}
  end

  # Everything else is a failure though
  def cast(_), do: :error

  def load({year, month, day}) do
    Date.from_erl({year, month, day})
  end

  def dump(%Date{} = date) do
    {:ok, Date.to_erl(date)}
  end
  def dump(_), do: :error
end
