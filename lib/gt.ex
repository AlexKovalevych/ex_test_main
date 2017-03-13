defmodule Gt do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start the endpoint when the application starts
      supervisor(Gt.Endpoint, []),
      worker(Redix, [Application.get_env(:gt, :redis), [name: :redix]]),
      # Start the Ecto repository
      worker(Gt.Currency.Cache, []),
      supervisor(Gt.Repo, []),
      worker(GuardianDb.ExpiredSweeper, []),
      supervisor(Gt.Amqp.Server, []),
      worker(Gt.CacheRegistry, []),
      worker(Gt.DataSourceRegistry, []),
      worker(Gt.PaymentCheckRegistry, []),
      supervisor(Gt.CacheServer, []),
      supervisor(Gt.DataSourceServer, []),
      supervisor(Gt.PaymentCheckServer, []),
      # Here you could define other workers and supervisors as children
      # worker(Gt.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gt.Supervisor]
    result = Supervisor.start_link(children, opts)

    # Continue incompleted workers only at the web server
    if !IEx.started? do
      Gt.CacheServer.continue_workers()
      Gt.DataSourceServer.continue_workers()
      Gt.PaymentCheckServer.continue_workers()
    end
    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Gt.Endpoint.config_change(changed, removed)
    :ok
  end
end
