use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :gt, Gt.Endpoint,
  secret_key_base: "MUJ4r0EHKHteNSsyTCFjXQOE0JG/7ap25FmNHsdCHjeJip2DA2YNnt4DiLNTy5XH"

# Configure your database
config :gt, Gt.Repo,
    adapter: Mongo.Ecto,
    database: "gt",
    hostname: "localhost",
    pool_size: 10
