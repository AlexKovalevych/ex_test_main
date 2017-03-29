defmodule Gt.Api.WlRest do
  use HTTPotion.Base
  alias Gt.Api.Wl.Player
  alias Gt.Api.Wl.EapiGame
  alias Gt.Api.Wl.BonusOffer
  alias Gt.Api.Wl.BonusBalance
  alias Gt.Api.Wl.Comment
  alias Gt.Api.Wl.AuthToken
  alias Gt.Api.Wl.Subresource
  alias Gt.Api.Wl.Portrait
  alias Gt.Api.Wl.RealBalance
  alias Gt.Api.Wl.PlayerAction
  alias Gt.Api.Wl.FilterQuery
  alias Gt.Api.Wl.StatsQuery
  alias Gt.Api.Wl.Compoints
  alias Gt.Api.Wl.GiftSpin
  alias Gt.Api.Wl.LevelCompoints
  alias Gt.Api.Wl.Wallet
  alias Gt.Api.Wl.WalletEvent
  alias Gt.Api.Wl.SubscriptionConfig
  alias Gt.Api.Wl.UserSubscriptions
  alias Gt.Api.Wl.Stats
  alias Gt.Api.Wl.PaymentSystemGroup
  alias Gt.Api.Wl.PaymentSystem
  alias Gt.Api.Wl.Transaction
  alias Gt.Api.Wl.PayoutConfirmation
  alias Gt.Api.Wl.PayoutRefusal
  alias Gt.Api.Wl.BatchPayoutRefusal
  require Logger

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
        true ->
          Logger.info("Success request", channel: :wl_rest, url: url)
          apply(on_success, [res])
        _ ->
          Logger.info("Code: #{res.status_code}, body: #{res.body}", channel: :wl_rest, url: url)
          {:error, res}
      end
    end
  end

  def process_request_headers([struct: struct] = headers) do
    filter_headers = case struct.filter do
      %StatsQuery{} -> StatsQuery.get_headers(struct.filter)
      %FilterQuery{} -> FilterQuery.get_headers(struct.filter)
      _ -> Keyword.new()
    end

    token = :crypto.hmac(:sha256, struct.key, struct.body) |> Base.encode16(case: :lower)
    headers
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
        players: Poison.decode(res.body, as: [%Player{}]),
        limit: limit,
        total: total,
      }}
    end)
  end

  def get_games(%__MODULE__{} = struct) do
    wl_request(:get, "eapi/round", struct, fn res ->
      %{"limit" => limit, "total" => total} = Regex.named_captures(~r/(?<offset>\d+)-(?<limit>\d+)\/(?<total>\d+)/, res.headers[:"content-range"])
      limit = String.to_integer(limit)
      total = String.to_integer(total)
      {:ok, %{
        games: Poison.decode(res.body, as: [%EapiGame{chances: %EapiGame{}}]),
        limit: limit,
        total: total,
      }}
    end)
  end

  def get_player(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}", struct, fn res ->
      Poison.decode(res.body, as: %Player{})
    end)
  end

  def new_player(%__MODULE__{} = struct, %Player{} = player) do
    body = Poison.encode!(player)
    wl_request(:post, "registrations",%{struct | body: body}, fn res ->
      Poison.decode(res.body, as: %Player{})
    end)
  end

  def update_player(%__MODULE__{} = struct, id, %Player{} = player) when is_binary(id) do
    body = Poison.encode!(player)
    wl_request(:put, "players/#{id}", %{struct | body: body}, fn res ->
      Poison.decode(res.body, as: %Player{})
    end)
  end

  def new_auth_token(%__MODULE__{} = struct, username, password) when is_binary(username) and is_binary(password) do
    body = %{"username" => username, "password" => password} |> Poison.encode!
    wl_request(:post, "auth-tokens", %{struct | body: body}, fn res ->
      Poison.decode(res.body, as: %AuthToken{})
    end)
  end

  def get_subresource(%__MODULE__{} = struct, id, subresource) when is_binary(id) and is_binary(subresource) do
    wl_request(:get, "players/#{id}/#{subresource}", struct, fn res ->
      {:ok, res}
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
      Poison.decode(res.body, as: [%Portrait{}])
    end)
  end

  def get_comments(%__MODULE__{} = struct, id) when is_binary(id)do
    wl_request(:get, "players/#{id}/comments", struct, fn res ->
      Poison.decode(res.body, as: [%Comment{}])
    end)
  end

  def get_bonus_offsers(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/bonusoffers", struct, fn res ->
      Poison.decode(res.body, as: [%BonusOffer{}])
    end)
  end

  def get_real_balance(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/balance/real", struct, fn res ->
      Poison.decode(res.body, as: %RealBalance{})
    end)
  end

  def add_real_balance(%__MODULE__{} = struct, id, %RealBalance{} = real_balance) when is_binary(id) do
    body = Poison.encode!(real_balance)
    wl_request(:post, "players/#{id}/balance/real", %{struct | body: body}, fn res ->
      Poison.decode(res.body, as: %Player{})
    end)
  end

  def get_bonus_balance(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/balance/bonuses", struct, fn res ->
      Poison.decode(res.body, as: %BonusBalance{})
    end)
  end

  def add_bonus_balance(%__MODULE__{} = struct, id, %BonusBalance{} = balance) when is_binary(id) do
    body = Poison.encode!(balance)
    wl_request(:post, "players/#{id}/balance/bonuses", %{struct | body: body}, fn res ->
      Poison.decode(res.body, as: %BonusBalance{})
    end)
  end

  def get_compoints(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/balance/compoints", struct, fn res ->
      Poison.decode(res.body, as: %Compoints{})
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
      Poison.decode(res.body, as: [%LevelCompoints{}])
    end)
  end

  def get_charge_reasons(%__MODULE__{} = struct) do
    wl_request(:get, "players/balance/charge-reasons", struct, fn res ->
      Poison.decode(res.body)
    end)
  end

  def get_balance_history(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/balance/history", struct, fn res ->
      Poison.decode(res.body, as: [%Wallet{event: %WalletEvent{}}])
    end)
  end

  def get_gift_spins(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/gift-spins", struct, fn res ->
      Poison.decode(res.body, as: [%GiftSpin{}])
    end)
  end

  def get_player_history(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/history", struct, fn res ->
      Poison.decode(res.body, as: [%PlayerAction{}])
    end)
  end

  def update_subscriptions(%__MODULE__{} = struct, id, %SubscriptionConfig{} = config) when is_binary(id) do
    body = Poison.encode!(config)
    wl_request(:put, "players/#{id}/subscriptions/0", %{struct | body: body}, fn res ->
      Poison.decode(res.body, as: %UserSubscriptions{})
    end)
  end

  def get_stats(%__MODULE__{} = struct) do
    wl_request(:get, "stats", struct, fn res ->
      Poison.decode(res.body, as: [%Stats{}])
    end)
  end

  def get_games_stats(%__MODULE__{} = struct) do
    wl_request(:get, "stats/games", struct, fn res ->
      Poison.decode(res.body)
    end)
  end

  def get_game_stats(%__MODULE__{} = struct, slug) do
    wl_request(:get, "stats/games/#{slug}", struct, fn res ->
      Poison.decode(res.body)
    end)
  end

  def get_payment_systems(%__MODULE__{} = struct) do
    wl_request(:get, "transactions/payment-systems", struct, fn res ->
      Poison.decode(res.body, as: [%PaymentSystemGroup{paymentSystems: %PaymentSystem{}}])
    end)
  end

  def get_deposits(%__MODULE__{} = struct) do
    wl_request(:get, "transactions/deposits", struct, fn res ->
      Poison.decode(res.body, as: [%Transaction{}])
    end)
  end

  def get_payouts(%__MODULE__{} = struct) do
    wl_request(:get, "transactions/payouts", struct, fn res ->
      Poison.decode(res.body, as: [%Transaction{}])
    end)
  end

  def get_refunds(%__MODULE__{} = struct) do
    wl_request(:get, "transactions/refunds", struct, fn res ->
      Poison.decode(res.body, as: [%Transaction{}])
    end)
  end

  def confirm_payout(%__MODULE__{} = struct, id, %PayoutConfirmation{} = confirmation) when is_binary(id) do
    body = Poison.encode!(confirmation)
    wl_request(:put, "transactions/payouts#{id}/status", %{struct | body: body}, fn res ->
      Poison.decode(res.body)
    end)
  end

  def refuse_payout(%__MODULE__{} = struct, id, %PayoutRefusal{} = refusal) when is_binary(id) do
    body = Poison.encode!(refusal)
    wl_request(:put, "transactions/payouts#{id}/status", %{struct | body: body}, fn res ->
      Poison.decode(res.body)
    end)
  end

  def batch_payout_refusal(%__MODULE__{} = struct, id, %BatchPayoutRefusal{} = refusal) when is_binary(id) do
    body = Poison.encode!(refusal)
    wl_request(:put, "transactions/players#{id}/payouts/reject", %{struct | body: body}, fn res ->
      Poison.decode(res.body)
    end)
  end

  def get_detailed_payouts(%__MODULE__{} = struct, id) when is_binary(id) do
    wl_request(:get, "players/#{id}/payouts", struct, fn res ->
      Poison.decode(res.body)
    end)
  end
end
