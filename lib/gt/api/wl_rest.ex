defmodule Gt.Api.WlRest do
  use HTTPotion.Base
  alias Gt.Api.Wl.Player
  alias Gt.Api.Wl.BonusOffer
  alias Gt.Api.Wl.BonusBalance
  alias Gt.Api.Wl.Comment
  alias Gt.Api.Wl.AuthToken
  alias Gt.Api.Wl.Subresource
  alias Gt.Api.Wl.Portrait
  alias Gt.Api.Wl.RealBalance
  alias Gt.Api.Wl.FilterQuery
  alias Gt.Api.Wl.Compoints
  alias Gt.Api.Wl.LevelCompoints

  @enforce_keys [:url]
  defstruct [url: nil, client: "", key: "", body: "", filter: nil]

  def process_url(uri, [headers: [struct: %__MODULE__{url: base_url}]]) do
    "#{String.trim_trailing(base_url, "\/")}/#{String.trim_leading(uri, "\/")}"
  end

  defmacro wl_request(method, url, struct, on_success) do
    quote do
      method = unquote(method)
      url = unquote(url)
      struct = unquote(struct)
      on_success = unquote(on_success)
      res = apply(__MODULE__, method, [url, [headers: [struct: struct]]])
      case HTTPotion.Response.success?(res) do
        true -> apply(on_success, [res])
        _ -> {:error, res}
      end
    end
  end

  def process_request_headers([struct: struct] = headers) do
    filter_headers = case struct.filter do
      %FilterQuery{} -> FilterQuery.get_headers(struct.filter)
      _ -> Keyword.new()
    end

    token = :crypto.hmac(:sha256, struct.key, struct.body) |> Base.encode16(case: :lower)
    headers = headers
    |> Keyword.delete(:struct)
    |> Keyword.put(:"Request", "Content-Type")
    |> Keyword.put(:"Response", "Accept")
    |> Keyword.put(:"Accept", "application/api-v1+json")
    |> Keyword.put(:"Rest-Public-Client", struct.client)
    |> Keyword.put(:"Rest-Security-Token", token)
    |> Keyword.merge(filter_headers)
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

  def process_response_body(body) do
    body |> IO.iodata_to_binary
  end

  #############
  # API methods
  #############

  def get_players(%__MODULE__{} = struct) do
    wl_request(:get, "players", struct, fn res ->
      %{"limit" => limit, "total" => total} = Regex.named_captures(~r/(?<offset>\d+)-(?<limit>\d+)\/(?<total>\d+)/, res.headers[:"content-range"])
      limit = String.to_integer(limit)
      total = String.to_integer(total)
      {:ok, %{
        players: Poison.decode!(res.body, as: [%Player{}]),
        limit: limit,
        total: total,
      }}
    end)
  end

  def get_player(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}", struct, fn res ->
      {:ok, Poison.decode!(res.body, as: %Player{})}
    end)
  end

  def new_player(%__MODULE__{} = struct, %Player{} = player) do
    body = Poison.encode!(player)
    wl_request(:post, "registrations",%{struct | body: body}, fn res ->
      {:ok, Poison.decode!(res.body, as: %Player{})}
    end)
  end

  def update_player(%__MODULE__{} = struct, id, %Player{} = player) when is_binary(id) do
    body = Poison.encode!(player)
    wl_request(:put, "players/#{id}", %{struct | body: body}, fn res ->
      {:ok, Poison.decode!(res.body, as: %Player{})}
    end)
  end

  def new_auth_token(%__MODULE__{} = struct, username, password) when is_binary(username) and is_binary(password) do
    body = %{"username" => username, "password" => password} |> Poison.encode!
    wl_request(:post, "auth-tokens", %{struct | body: body}, fn res ->
      {:ok, Poison.decode!(res.body, as: %AuthToken{})}
    end)
  end

  def get_subresource(%__MODULE__{} = struct, id, subresource) when is_binary(id) and is_binary(subresource) do
    wl_request(:get, "players/#{id}/#{subresource}", struct, fn res ->
      {:ok, res.body}
    end)
  end

  def new_subresource(%__MODULE__{} = struct, id, %Subresource{} = subresource) when is_binary(id)do
    body = Poison.encode!(subresource)
    wl_request(:post, "players/#{id}/#{subresource.name}", %{struct | body: body}, fn res ->
      {:ok, res}
    end)
  end

  def update_subresource(%__MODULE__{} = struct, id, %Subresource{} = subresource) when is_binary(id)do
    body = Poison.encode!(subresource)
    wl_request(:put, "players/#{id}/#{subresource.name}", %{struct | body: body}, fn res ->
      {:ok, res}
    end)
  end

  def get_portraits(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/portraits", struct, fn res ->
      {:ok, Poison.decode!(res.body, as: [%Portrait{}])}
    end)
  end

  def get_comments(%__MODULE__{} = struct, id) when is_binary(id)do
    wl_request(:get, "players/#{id}/comments", struct, fn res ->
      {:ok, Poison.decode!(res.body, as: [%Comment{}])}
    end)
  end

  def get_bonus_offsers(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/bonusoffers", struct, fn res ->
      {:ok, Poison.decode!(res.body, as: [%BonusOffer{}])}
    end)
  end

  def get_real_balance(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/balance/real", struct, fn res ->
      {:ok, Poison.decode!(res.body, as: %RealBalance{})}
    end)
  end

  def add_real_balance(%__MODULE__{} = struct, id, %RealBalance{} = real_balance) when is_binary(id) do
    body = Poison.encode!(real_balance)
    wl_request(:post, "players/#{id}/balance/real", %{struct | body: body}, fn res ->
      {:ok, Poison.decode!(res.body, as: %Player{})}
    end)
  end

  def get_bonus_balance(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/balance/bonuses", struct, fn res ->
      {:ok, Poison.decode!(res.body, as: %BonusBalance{})}
    end)
  end

  def add_bonus_balance(%__MODULE__{} = struct, id, %BonusBalance{} = balance) when is_binary(id) do
    body = Poison.encode!(balance)
    wl_request(:post, "players/#{id}/balance/bonuses", %{struct | body: body}, fn res ->
      {:ok, Poison.decode!(res.body, as: %BonusBalance{})}
    end)
  end

  def get_compoints(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/balance/compoints", struct, fn res ->
      {:ok, Poison.decode!(res.body, as: %Compoints{})}
    end)
  end

  def add_compoints(%__MODULE__{} = struct, id, %Compoints{} = compoints) when is_binary(id) do
    body = Poison.encode!(compoints)
    wl_request(:post, "players/#{id}/balance/compoints", %{struct | body: body}, fn res ->
      {:ok, res}
    end)
  end

  def get_level_compoints(%__MODULE__{} = struct) do
    wl_request(:get, "levels/compoints", struct, fn res ->
      {:ok, Poison.decode!(res.body, as: [%LevelCompoints{}])}
    end)
  end

  def get_charge_reasons(%__MODULE__{} = struct) do
    wl_request(:get, "players/balance/charge-reasons", struct, fn res ->
      {:ok, Poison.decode!(res.body)}
    end)
  end

    #/**
     #* @param  array $id
     #* @return array
     #*/
    #public function getBalanceHistory($id)
    #{
        #$url = $this->getUrl(sprintf('players/%s/balance/history', $id));
        #$response = $this->getRequest($url);

        #return $this->parseResponse((string) $response->getBody(), 'array<Globotunes\WLRestApi\Response\Wallet>');
    #}

    #/**
     #* @param  array $id
     #* @return array
     #*/
    #public function getGiftSpins($id)
    #{
        #$url = $this->getUrl(sprintf('players/%s/gift-spins', $id));
        #$response = $this->getRequest($url);

        #return $this->parseResponse((string) $response->getBody(), 'array<Globotunes\WLRestApi\Response\GiftSpin>');
    #}

    #/**
     #* @param  array $id
     #* @return array
     #*/
    #public function getPlayerHistory($id)
    #{
        #$url = $this->getUrl(sprintf('players/%s/history', $id));
        #$response = $this->getRequest($url);

        #return $this->parseResponse((string) $response->getBody(), 'array<Globotunes\WLRestApi\Response\PlayerAction>');
    #}

    #/**
     #* @param string $id
     #* @param SubscriptionConfig $config
     #* @return array
     #*/
    #public function updateSubscriptions($id, SubscriptionConfig $config)
    #{
        #$url = $this->getUrl(sprintf('players/%s/subscriptions/0', $id));
        #$body = $this->serializer->serialize($config, 'json');

        #$response = $this->putRequest($url, $body);

        #return $this->parseResponse((string) $response->getBody(), 'Globotunes\WLRestApi\Response\UserSubscriptions');
    #}
      #/**
     #* @param  FilterQueryBuilder|null  $queryBuilder
     #* @return \Globotunes\WLRestApi\Response\EapiGamesResponse
     #*/
    #public function getGames(FilterQueryBuilder $queryBuilder = null)
    #{
        #$url = $this->getUrl('api/eapi/round');
        #$response = $this->getRequest($url, $queryBuilder);

        #$contentRange = $response->getHeader('Content-Range');
        #if (is_array($contentRange)) {
            #$contentRange = array_shift($contentRange);
        #}

        #preg_match('`(?<offset>\d+)-(?<limit>\d+)\/(?<total>\d+)`', $contentRange, $matched);
        #$eapiGamesResponse = new EapiGamesResponse();

        #return $eapiGamesResponse
            #->setLimit((int) $matched['limit'])
            #->setTotal((int) $matched['total'])
            #->setGames($this->parseResponse((string) $response->getBody(), 'array<Globotunes\WLRestApi\Response\EapiGame>'));
        #;
    #}

        #/**
     #* @param  StatsQueryBuilder|null $queryBuilder
     #* @return array
     #*/
    #public function getStats(StatsQueryBuilder $queryBuilder = null)
    #{
        #$url = $this->getUrl('stats');
        #$response = $this->getRequest($url, $queryBuilder);

        #return $this->parseResponse((string) $response->getBody(), 'array<Globotunes\WLRestApi\Response\Stats>');
    #}

    #/**
     #* @todo  Not tested, may not work
     #*
     #* @param  StatsQueryBuilder|null $queryBuilder
     #* @return \GuzzleHttp\Message\ResponseInterface
     #*/
    #public function getGamesStats(StatsQueryBuilder $queryBuilder = null)
    #{
        #$url = $this->getUrl('stats/games');
        #$response = $this->getRequest($url, $queryBuilder);

        #return $response;
    #}

    #/**
     #* @todo  Not tested, may not work
     #*
     #* @param  string                 $gameSlug
     #* @param  StatsQueryBuilder|null $queryBuilder
     #* @return \GuzzleHttp\Message\ResponseInterface
     #*/
    #public function getGameStats($gameSlug, StatsQueryBuilder $queryBuilder = null)
    #{
        #$url = $this->getUrl(sprintf('stats/games/%s', $gameSlug));
        #$response = $this->getRequest($url, $queryBuilder);

        #return $response;
    #}

        #/**
     #* @return array
     #*/
    #public function getPaymentSystems()
    #{
        #$url = $this->getUrl('transactions/payment-systems');
        #$response = $this->getRequest($url);

        #return $this->parseResponse((string) $response->getBody(), 'array<Globotunes\WLRestApi\Response\PaymentSystemGroup>');
    #}

    #/**
     #* @param  FilterQueryBuilder|null $queryBuilder
     #* @return array
     #*/
    #public function getDeposits(FilterQueryBuilder $queryBuilder = null)
    #{
        #$url = $this->getUrl('transactions/deposits');
        #$response = $this->getRequest($url, $queryBuilder);

        #return $this->parseResponse((string) $response->getBody(), 'array<Globotunes\WLRestApi\Response\Transaction>');
    #}

    #/**
     #* @param  FilterQueryBuilder|null $queryBuilder
     #* @return array
     #*/
    #public function getPayouts(FilterQueryBuilder $queryBuilder = null)
    #{
        #$url = $this->getUrl('transactions/payouts');
        #$response = $this->getRequest($url, $queryBuilder);

        #return $this->parseResponse((string) $response->getBody(), 'array<Globotunes\WLRestApi\Response\Transaction>');
    #}

    #/**
     #* @param  FilterQueryBuilder|null $queryBuilder
     #* @return array
     #*/
    #public function getRefunds(FilterQueryBuilder $queryBuilder = null)
    #{
        #$url = $this->getUrl('transactions/refunds');
        #$response = $this->getRequest($url, $queryBuilder);

        #return $this->parseResponse((string) $response->getBody(), 'array<Globotunes\WLRestApi\Response\Transaction>');
    #}

    #/**
     #* @todo Not tested, may not work
     #*
     #* @param  string             $id
     #* @param  PayoutConfirmation $payoutConfirmation
     #* @return \GuzzleHttp\Message\ResponseInterface
     #*/
    #public function condirmPayout($id, PayoutConfirmation $payoutConfirmation)
    #{
        #$url = $this->getUrl(sprintf('transactions/payouts/%s/status', $id));
        #$body = $this->serializer->serialize($payoutConfirmation, 'json');
        #$response = $this->putRequest($url, $body);

        #return $response;
    #}

    #/**
     #* @todo Not tested, may not work
     #*
     #* @param  string        $id
     #* @param  PayoutRefusal $payoutRefusal
     #* @return \GuzzleHttp\Message\ResponseInterface
     #*/
    #public function refusePayout($id, PayoutRefusal $payoutRefusal)
    #{
        #$url = $this->getUrl(sprintf('transactions/payouts/%s/status', $id));
        #$body = $this->serializer->serialize($payoutRefusal, 'json');
        #$response = $this->putRequest($url, $body);

        #return $response;
    #}

    #/**
     #* @todo Not tested, may not work
     #*
     #* @param  string             $id
     #* @param  BatchPayoutRefusal $payoutRefusal
     #* @return \GuzzleHttp\Message\ResponseInterface
     #*/
    #public function batchRefusePayout($id, BatchPayoutRefusal $payoutRefusal)
    #{
        #$url = $this->getUrl(sprintf('transactions/players/%s/payouts/reject', $id));
        #$body = $this->serializer->serialize($payoutRefusal, 'json');
        #$response = $this->putRequest($url, $body);

        #return $response;
    #}

    #/**
     #* @todo Not tested, may not work
     #*
     #* @param  string                  $id
     #* @param  FilterQueryBuilder|null $queryBuilder
     #* @return \GuzzleHttp\Message\ResponseInterface
     #*/
    #public function getDetailedPayouts($id, FilterQueryBuilder $queryBuilder = null)
    #{
        #$url = $this->getUrl(sprintf('players/%s/payouts', $id));
        #$response = $this->getRequest($url, $queryBuilder);

        #return $response;
    #}


end
