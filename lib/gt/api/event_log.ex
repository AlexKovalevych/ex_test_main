defmodule Gt.Api.EventLog do
  use HTTPotion.Base
  alias Gt.Api.EventLogResponse
  alias Gt.Api.EventLogEvent
  require Logger

  @enforce_keys [:url]
  defstruct [url: nil, app_key: nil, private_key: "", method: nil, body: "", params: %{}]

  defmacro send_request(method, url, struct, on_success) do
    quote do
      method = unquote(method)
      url = unquote(url)
      struct = unquote(struct)
      on_success = unquote(on_success)
      res = apply(__MODULE__, method, [url, [struct: struct]])
      case HTTPotion.Response.success?(res) do
        true ->
          Logger.info("Success request", channel: :event_log, url: url)
          apply(on_success, [res])
        _ ->
          Logger.info("Code: #{res.status_code}, body: #{res.body}", channel: :event_log, url: url)
          {:error, res}
      end
    end
  end

  def process_url(uri, [struct: %__MODULE__{url: base_url} = struct]) do
    hash = :crypto.hash(:sha, :crypto.strong_rand_bytes(1024)) |> Base.encode16(case: :lower)
    params = struct.params
    |> Map.put("api_salt", hash)
    |> Map.put("api_time", :os.system_time(:millisecond))
    |> Map.put("api_key", struct.app_key)
    path = "/#{String.trim(uri, "/")}"
    sign = "#{struct.method |> to_string |> String.upcase}:#{path}:#{params |> Map.values |> Enum.join(",")}:#{struct.body}"
    sign = :crypto.hash(:sha256, sign) |> Base.encode16(case: :lower)
    params = params
             |> Map.put("api_secret", sign)
             |> URI.encode_query()
    "#{String.trim_trailing(base_url, "\/")}#{path}?#{params}"
  end

  def get(url, [struct: struct] = options) do
    request(:get, url, Keyword.put(options, :struct, %{struct | method: :get}))
  end

  def get!(url, [struct: struct] = options) do
    request!(:get, url, Keyword.put(options, :struct, %{struct | method: :get}))
  end

  def post(url, [struct: struct] = options) do
    request(:post, url, Keyword.put(options, :struct, %{struct | method: :post}))
  end

  def post!(url, [struct: struct] = options) do
    request!(:post, url, Keyword.put(options, :struct, %{struct | method: :post}))
  end

  def read_events(%__MODULE__{} = struct, uri, id \\ 0) when is_integer(id) do
    send_request(:get, uri, %{struct | params: %{"cm" => "eventlog", "id" => id, "limit" => 100}}, fn res ->
      Poison.decode(res, as: %EventLogResponse{events: [%EventLogEvent{}]})
    end)
  end

  def get_register_event(%__MODULE__{} = struct, uri, user_id) when is_binary(user_id) do
    send_request(:get, uri, %{struct | params: %{"cm" => "user_data", "user_id" => user_id, "userid" => user_id}}, fn res ->
      Poison.decode(res, as: %EventLogResponse{events: [%EventLogEvent{}]})
    end)
  end

end
