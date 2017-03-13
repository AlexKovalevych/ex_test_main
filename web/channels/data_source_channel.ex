defmodule Gt.DataSourceChannel do
  use Gt.Web, :channel
  use Guardian.Channel
  alias Gt.DataSource
  alias Gt.Repo

  def join("data_source:" <> _data_source_id, %{claims: _claim, resource: resource}, socket) do
    Gettext.put_locale(Gt.Gettext, resource.locale)
    {:ok, %{message: "Welcome #{resource.email}"}, socket}
  end

  # Deny joining the channel if the user isn't authenticated
  def join("data_source:" <> _data_source_id, _, _socket) do
    {:error, %{error: "not authorized, are you logged in?"}}
  end

  def handle_in("data_source:update", _, socket) do
    "data_source:" <> data_source_id = socket.topic
    case Repo.get(DataSource, data_source_id) do
      nil -> {:noreply, socket}
      data_source -> {:reply, {:ok, data_source}, socket}
    end
  end

end
