defmodule Gt.Api.Wl.Transaction do
  @derive [Poison.Encoder]

  defstruct [:id,
             :player,
             :type,
             :sum,
             :currency,
             :status,
             :transaction_id,
             :created_at,
             :processed_at,
             :payment_system,
             :payment_group,
             :wallet_id,
             :callback,
             :ip_address,
             :external_id,
             :user_agent
           ]
end
