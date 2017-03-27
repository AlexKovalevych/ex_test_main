defmodule Gt.Api.WlRest do
  use HTTPotion.Base
  alias Gt.Api.Wl.Player

  defstruct [:url, :client, :key, :body]

  def process_url(uri, [headers: [struct: %__MODULE__{url: base_url}]]) do
    "#{String.trim_trailing(base_url, "\/")}/#{String.trim_leading(uri, "\/")}"
  end

  def process_request_headers([struct: struct] = headers) do
    token = :crypto.hmac(:sha256, struct.key, struct.body) |> Base.encode16(case: :lower)
    headers
    |> Keyword.delete(:struct)
    |> Keyword.put(:"Request", "Content-Type")
    |> Keyword.put(:"Response", "Accept")
    |> Keyword.put(:"Accept", "application/api-v1+json")
    |> Keyword.put(:"Rest-Public-Client", struct.client)
    |> Keyword.put(:"Rest-Security-Token", token)

    #if ($queryBuilder) {
        #$headers = array_merge($headers, $queryBuilder->getHeaders());
    #}

  end

  def put(url, [headers: headers] = options) do
    request(:put, url, Keyword.put(options, :headers, add_put_header(headers)))
  end

  def put!(url, [headers: headers] = options) do
    request!(:put, url, Keyword.put(options, :headers, add_put_header(headers)))
  end

  defp add_put_header(headers) do
    Keyword.put(headers, :"X-HTTP-METHOD-OVERRIDE", "PUT")
  end

  #def process_response_body(body) do
    #body |> IO.iodata_to_binary |> :jsx.decode
    #|> Enum.map fn ({k, v}) -> { String.to_atom(k), v } end
    #|> :orddict.from_list
  #end<

  def get_players(%__MODULE__{} = struct) do
    __MODULE__.get("players", headers: [struct: struct])
  end

  def new_player(%__MODULE__{} = struct, %Player{} = player) do
    body = Poison.encode!(player)
    __MODULE__.post("registrations", headers: [struct: %{struct | body: body}])
  end

end
