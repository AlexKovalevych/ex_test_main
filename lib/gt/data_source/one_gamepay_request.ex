defmodule Gt.DataSource.OneGamepayRequest do
  require Logger

  @doc """
    1. Get login cookies (__cfduid, IPSP-CLIENT-SID)
      curl -XPOST "https://cliff.1gamepay.com/auth/login" -s --data "foster\forms\AuthForm[login]=<login>&foster\forms\AuthForm[password]=<password>&foster\forms\AuthForm[rememberMe]=0" -i

    2. Get form values at https://cliff.1gamepay.com/statistics/index

    3. Change dates
        $values['StatisticsBaseFilterForm']['dateFrom'] = (string) $startDate;

        // 1Gamepay will return report by period [$startDate; $endDate)
        $fixedEndDate = $endDate->copy()->addDay();
        $values['StatisticsBaseFilterForm']['dateTo'] = (string) $fixedEndDate;

    3. Send export request to https://cliff.1gamepay.com/statistics/export/?report=base with form params
  """
  def process_api(data_source) do
    body = [
      "foster\forms\AuthForm[login]=#{data_source.login}",
      "foster\forms\AuthForm[password]=#{data_source.password}",
      "foster\forms\AuthForm[rememberMe]=0"
    ]
    |> Enum.join("&")

    url = "#{data_source.host}/auth/login"
    Logger.info("Request #{url} with body: #{inspect(body)}")
    login_response = HTTPotion.post(url, body: body)
    headers = ["Cookie": get_cookies(login_response.headers["set-cookie"])]
    url = "#{data_source.host}/statistics/index"
    Logger.info("Request #{url} with headers: #{inspect(headers)}")
    index_response = HTTPotion.get(url, headers: headers)
    body = index_response.body
    form = body
           |> Floki.find("form")
           |> Enum.filter(fn form ->
             value = form
             |> Floki.find("input[type=submit]")
             |> Floki.attribute("value")
             value == ["Сформировать отчет"] || value == ["Generate report"]
           end)
           |> List.first

    if !form, do: exit("Can't find download form")

    form_values = form
    |> Floki.find("input")
    |> Enum.filter_map(
      fn el ->
        Floki.attribute(el, "value") != [""] &&
        Floki.attribute(el, "name") != [] &&
        Floki.attribute(el, "type") != ["button"]
      end,
      fn el ->
        name = Floki.attribute(el, "name") |> List.first
        value = cond do
          name == "StatisticsBaseFilterForm[dateFrom]" -> Timex.format!(data_source.start_at, "{ISOdate}")
          name == "StatisticsBaseFilterForm[dateTo]" -> Timex.format!(data_source.end_at |> Timex.shift(days: 1), "{ISOdate}")
          true -> Floki.attribute(el, "value") |> List.first
        end
        "#{name}=#{value}"
      end
    )
    |> Enum.join("&")

    url = "#{data_source.host}/statistics/export/?report=base"
    Logger.info("Request #{url} with body: #{inspect(body)} and headers: #{inspect(headers)}")
    response = HTTPotion.post(url, body: form_values, headers: headers)
    Logger.info("CSV request response: #{response.body}")
  end

  defp get_cookies(cookie_headers) when is_binary(cookie_headers) do
    cookie_headers
    |> String.split(";")
    |> List.first
  end

  defp get_cookies(cookie_headers) when is_list(cookie_headers) do
    cookie_headers
    |> Enum.map(&get_cookies/1)
    |> Enum.join(", ")
  end

end
