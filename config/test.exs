use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gt, Gt.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :gt, Gt.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "gt_test",
  username: "gt",
  password: "gt",
  hostname: "localhost",
  port: "5432"
