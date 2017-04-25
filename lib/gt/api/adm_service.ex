defmodule Gt.Api.AdmService do
  defmodule Gt.Api.AdmService.Auth do
    defstruct [:key, :expire]
  end

  import SweetXml
  use HTTPotion.Base
  require Logger
  alias Gt.Api.AdmService.Auth

  defstruct [host: nil,
             port: 80,
             path: nil,
             user: nil,
             login: nil,
             pass: nil,
             name: nil,
             expired: 60 * 60 * 24 * 365,
             srv: nil,
             options: %{},
             encoding: "utf8"
           ]

  defp request_id(url, method, body \\ nil) do
    id = "#{url}#{inspect(body)}#{method}"
    :crypto.hash(:md5, id) |> Base.encode16(case: :lower)
  end

  defp run_command(%__MODULE__{srv: srv, encoding: encoding} = struct, command, %{} = args, slave \\ false) do
    case !is_eapi(struct) && !is_170(struct) && is_nil(srv) do
      true -> {:error, "SRV is null"}
      _ ->
        # select get or post, use post for big data, calculate data size
        # and if data more than 2kb, use post
        {req_id, response} = case Poison.encode!(args) |> String.length > 2048 do
          false ->
            args = Map.put(args, "cm", command)
            url = generate_url(struct, args, slave)
            req_id = request_id(url, :get)
            Logger.info("Start request #{req_id}")
            {req_id, get(url)}
          true ->
            get_args = %{"cm" => command}
            {args, get_args} = case Map.get(args, "mng_auth") do
              nil -> {args, get_args}
              mng_auth -> {Map.delete(args, "mng_auth"), Map.put(get_args, "mng_auth", mng_auth)}
            end
            url = generate_url(struct, get_args, slave)
            req_id = request_id(url, :post)
            Logger.info("Start request #{req_id}")
            {req_id, post(url, body: URI.encode_query(args))}
        end
        Logger.info("End request #{req_id}")

        if HTTPotion.Response.success?(response) do
          {:ok, response.body |> to_utf8(encoding)}
        else
          {:error, response}
        end
    end
  end

  defp to_utf8(value, encoding \\ "utf8") do
    {:ok, reg} = Regex.compile("^" <> <<239, 187, 191>>)
    value = String.replace(value, reg, "")
    case encoding do
      "utf8" -> :iconv.convert(encoding, encoding, value)
      _ -> :iconv.convert(encoding, "windows-1251", value)
    end
  end

  defp to_server_encoding(value, encoding \\ "utf8") do
    if encoding == "utf8", do: :iconv.convert("utf8", "windows-1251", value), else: value
  end

  defp generate_url(%__MODULE__{} = struct, args, slave \\ false) do
    %{port: port, host: host, path: path, login: login, pass: pass} = struct
    %{path: path, query: query} = URI.parse(path)
    query = if query, do: URI.decode_query(query), else: %{}
    query = Map.merge(args, query)
    scheme = if port == 443, do: "https", else: "http"
    query = if !Map.get(args, "mng_auth") do
      query
      |> Map.put("login", login)
      |> Map.put("password", pass)
    else
      query
    end
    %URI{port: port, host: host, path: path, scheme: scheme, query: URI.encode_query(query)} |> to_string
  end

  def new_auth(%__MODULE__{name: name, expired: expired} = struct) do
    name = "globotunes_#{name}"
    case run_command(struct, "create_mng", %{"strid" => name, "expire" => expired, "format" => "xml"}) do
      {:error, reason} -> {:error, reason}
      {:ok, xml} ->
        if is_nil(xml) do
          {:error, "Invalid response"}
        else
          status = xml |> xpath(~x"//result/@status")
          auth = xml |> xpath(~x"//result/mng_auth/text()")
          if status == 'ok' && !is_nil(auth) do
            {:ok, %Auth{key: to_string(auth), expire: :os.system_time(:second) + expired}}
          else
            {:error, "Invalid response"}
          end
        end
    end
  end

  def is_170(%__MODULE__{options: options}) do
    Map.get(options, "type") == "170"
  end

  def is_eapi(%__MODULE__{options: options}) do
    Map.get(options, "type", "") |> String.downcase == "eapi"
  end

  def get_transactions(%__MODULE__{} = struct, %Auth{} = auth, from, to, limit \\ nil, order \\ nil, offset \\ nil) do
    params_map = %{
      "userid" => {:multiple_id, nil},
      "projectid" => {:multiple_id, nil},
      "start_date" => {:date, from},
      "end_date" => {:date, to},
      "status" => {:multiple_id, nil},
      "trid" => {:integer, nil},
      "system" => {:string, nil},
      "info" => {:string, nil},
      "cashout" => {:integer, 0},
      "orderdirect" => {:string, order},
      "limit" => {:integer, limit},
      "startid" => {:integer, offset},
      "no_comment" => {:boolean, true}
    }

    params = prepare_params(struct, params_map)
             |> Map.put("mng_auth", auth)
             |> Map.put("format", "xml")

    case run_command(struct, "transaction_list", params, true) do
      {:error, response} -> {:error, response}
      {:ok, body} ->
        body = body
        |> HtmlEntities.decode
        |> String.replace("&", "&amp;")
        |> String.replace(~r/UserComment=\".*?\"\s/is, "")
        {:ok, body}
    end
  end

  defp prepare_params(%__MODULE__{encoding: encoding}, params) do
    params
    |> Enum.map(
      fn {k, {type, value}} ->
        case type do
          :multiple_id ->
            if is_list(value), do: Enum.join(value, ","), else: value |> String.trim
          :true ->
            if value, do: true, else: false
          :integer ->
            to_int(value)
          :string ->
            value
            |> HtmlEntities.decode
            |> to_server_encoding(encoding)
          :boolean ->
            if value, do: 1, else: 0
          :boolean_revert ->
            if value, do: 0, else: 1
          :date ->
            Timex.format(value, "{ISOdate}")
          :time ->
            Timex.format(value, "{ISOtime}")
          :timestamp ->
            Timex.to_unix(value)
          :boolean_switch ->
            if value, do: "on", else: "off"
          :utf8 ->
            value
          _ ->
            value
        end
      end
    )
    |> Enum.filter(fn {k, {type, value}} ->
      is_nil(value) && value != ""
    end)
  end

  defp to_int(value) when is_float(value), do: round(value)

  defp to_int(value) when is_integer(value), do: value

  defp to_int(value) when is_binary(value), do: String.to_integer value
end
