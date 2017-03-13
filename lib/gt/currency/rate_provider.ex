defmodule Gt.RateProvider do
  @type sum :: integer() | float()

  @doc """
  Converts from one currency to another using rate for the given date
  """
  @callback convert(String.t, String.t, %NaiveDateTime{}, sum) :: sum

  @doc """
  Converts to USD using rate for the given date
  """
  @callback to_usd(String.t, %NaiveDateTime{}, sum) :: sum

  @doc """
  Get rate for the currency for the given date
  """
  @callback get_rate(String.t, %NaiveDateTime{}) :: sum
end
