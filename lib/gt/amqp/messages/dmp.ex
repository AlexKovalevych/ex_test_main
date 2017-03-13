defmodule Gt.Amqp.Messages.Dmp do
  alias Gt.Payment
  alias Gt.Amqp.Messages.Hit
  use Timex

  @enforce_keys [:project_id, :user_id, :time, :event, :ip]
  defstruct project_id: "", user_id: "", time: "", event: "hit", event_id: "", ip: "", amount: nil, amount_user: "", tid: nil, currency: "", uri: ""

  @event_hit "hit"
  @event_registration "reg"
  @event_authorization "auth"
  @event_deposit "deposit"
  @event_withdrawal "withdrawal"

  def create_by_payment(payment, user_item_id) do
    if dmp_project?(payment.project.item_id) do
      type_dep = Payment.type(:deposit)
      type_wdr = Payment.type(:withdrawal)
      event = case payment.type do
        ^type_dep ->
          @event_deposit
        ^type_wdr ->
          @event_withdrawal
        _ -> nil
      end
      dmp_message = %__MODULE__{
        user_id: user_item_id,
        amount: payment.sum,
        ip: (Map.get(payment, :info, "") || "") |> Map.get("ip", nil),
        time: Timex.to_unix(payment.date),
        project_id: payment.project.item_id,
        tid: payment.item_id,
        event: event,
      }
      if dmp_message.event, do: GenServer.call(:gt_amqp_dmp, {:send, :dmp, Poison.encode!(dmp_message)})
    end
  end

  def create_by_hit(%Hit{} = hit) do
    if dmp_project?(hit.projectItemId) do
      dmp_message = %__MODULE__{
        user_id: hit.userItemId,
        ip: Enum.join(hit.ips, ","),
        time: hit.time,
        project_id: hit.projectItemId,
        event: @event_hit,
        uri: hit.url,
      }
      GenServer.call(:gt_amqp_dmp, {:send, :dmp, Poison.encode!(dmp_message)})
    end
  end

  def create_by_user(project_user) do
    if dmp_project?(project_user.project.item_id) do
      dmp_message = %__MODULE__{
        user_id: project_user.item_id,
        project_id: project_user.project.item_id,
        time: Timex.to_unix(project_user.reg_d),
        ip: project_user.reg_ip,
        event: @event_registration,
      }
      GenServer.call(:gt_amqp_dmp, {:send, :dmp, Poison.encode!(dmp_message)})
    end
  end

  def dmp_project?(project_item_id) do
    Application.get_env(:gt, :dmp) |> Map.get(String.to_atom(project_item_id))
  end

end
