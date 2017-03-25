defprotocol Gt.PaymentCheck.Script do
  @doc "Interface for processing payment checks"

  @fallback_to_any true

  def preprocess(struct)

  def channel_sum_1gp(struct, transaction, one_gamepay_transaction)

  def sum_1gp(struct, transaction, one_gamepay_transaction)

  def currency_1gp(struct, one_gamepay_transaction)

  def channel_currency_1gp(struct, one_gamepay_transaction)

  def match_1gp_sum(struct, transaction, one_gamepay_sum, one_gamepay_channel_sum)

  def calculate_fee(struct, transaction)

  def parse_date(struct, path, cell)
end
