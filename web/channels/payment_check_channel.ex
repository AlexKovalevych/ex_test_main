defmodule Gt.PaymentCheckChannel do
  use Gt.Web, :channel
  use Guardian.Channel
  alias Gt.PaymentCheck
  alias Gt.Repo

  def join("payment_check:" <> _payment_check_id, %{claims: _claim, resource: resource}, socket) do
    Gettext.put_locale(Gt.Gettext, resource.locale)
    {:ok, %{message: "Welcome #{resource.email}"}, socket}
  end

  # Deny joining the channel if the user isn't authenticated
  def join("payment_check:" <> _payment_check_id, _, _socket) do
    {:error, %{error: "not authorized, are you logged in?"}}
  end

  def handle_in("payment_check:update", _, socket) do
    "payment_check:" <> payment_check_id = socket.topic
    case Repo.get(PaymentCheck, payment_check_id) do
      nil -> {:noreply, socket}
      payment_check -> {:reply, {:ok, payment_check}, socket}
    end
  end

end
