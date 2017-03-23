defprotocol Gt.PaymentCheck.Script do
  @doc "Interface for processing payment checks"

  @fallback_to_any true

  def preprocess(struct)
end
