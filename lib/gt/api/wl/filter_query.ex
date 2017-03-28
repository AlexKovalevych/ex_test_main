defmodule Gt.Api.Wl.FilterQuery do
  defstruct [offset: 0, limit: 15, filters: %{}, sort: %{}, fields: %{}]

  def get_headers(%__MODULE__{} = struct) do
    Keyword.new()
    |> Keyword.put(:"Rest-Range", "#{struct.offset}-#{struct.limit}")
    |> Keyword.put(:"Rest-Filter", struct.filters)
    |> Keyword.put(:"Rest-Sort", struct.sort)
    |> Keyword.put(:"Rest-Fields", struct.fields)
    |> Enum.filter_map(
      fn {_, v} ->
        !is_nil(v) || !Enum.empty(v)
      end,
      fn {k, v} ->
        v = cond do
          is_binary(v) -> v
          true -> Poison.encode!(v)
        end
        {k, v}
      end
    )
  end
end
