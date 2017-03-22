defprotocol Gt.PaymentCheck.Script do
  @doc "Interface for processing payment checks"

  @fallback_to_any true

  def run(payment_check)

  def process_file(payment_check, path_with_index, total_files)
end
