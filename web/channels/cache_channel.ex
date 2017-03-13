defmodule Gt.CacheChannel do
  use Gt.Web, :channel
  use Guardian.Channel
  alias Gt.Cache
  alias Gt.Repo

  def join("cache:" <> _, %{resource: resource}, socket) do
    Gettext.put_locale(Gt.Gettext, resource.locale)
    {:ok, %{message: "Welcome #{resource.email}"}, socket}
  end

  # Deny joining the channel if the user isn't authenticated
  def join("cache:" <> _, _, _) do
    {:error, %{error: "not authorized, are you logged in?"}}
  end

  def handle_in("cache:update", _, socket) do
    "cache:" <> cache_id = socket.topic
    case Repo.get(Cache, cache_id) do
      nil -> {:noreply, socket}
      cache -> {:reply, {:ok, cache}, socket}
    end
  end

end
