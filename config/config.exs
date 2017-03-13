# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :gt, Gt.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "nS/NptZrKot8DXmcg3BMni0g4rkvhKFzUHIz3g4JP+SuMC8FG0yMmax2kck/69Cn",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Gt.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :guardian, Guardian,
  allowed_algos: ["HS512"], # optional
  verify_module: Guardian.JWT,  # optional
  issuer: "Gt",
  ttl: { 30, :days },
  verify_issuer: true, # optional
  secret_key: to_string(Mix.env),
  serializer: Gt.Auth.GuardianSerializer,
  hooks: GuardianDb,
  permissions: %{
    default: [
      :read_token,
      :revoke_token,
    ]
  }

config :gt, Gt.Gettext,
  default_locale: "en"

config :guardian_db, GuardianDb,
  repo: Gt.Repo,
  sweep_interval: 60 # 60 minutes

config :ueberauth, Ueberauth,
  providers: [
    identity: {Ueberauth.Strategy.Identity, [callback_methods: ["POST"]]}
  ]

config :kerosene, theme: :bootstrap4

config :gt,
  locales: ["ru", "en"],
  permissions: %{
    "dashboard" => %{
      "dashboard_index" => []
    },
    "finance" => %{
      "payments_check" => [],
      "payment_systems" => [],
      "funds_flow" => [],
      "monthly_balance" => []
    },
    "statistics" => %{
      "consolidated_report" => [],
      "ltv_report" => [],
      "segments_report" => [],
      "retention" => [],
      "activity_waves" => [],
      "timeline_report" => [],
      "cohorts_report" => [],
      "universal_report" => []
    },
    "calendar_events" => %{
      "events_list" => [],
      "events_types_list" => [],
      "events_groups_list" => []
    },
    "players" => %{
      "multiaccounts" => [],
      "signup_channels" => []
    }
  },
  redis: "redis://localhost"

config :gt, :amqp,
  %{
    connections: %{
      default: "amqp://guest:guest@localhost",
      dmp: "amqp://guest:guest@localhost",
      globotunes: "amqp://guest:guest@localhost",
    },
    producers: %{
      iqsms: %{
        connection: :default,
        exchange: "reactions",
        queue: "send_sms_iqsms",
        routing: "sms.iqsms",
        sender: "iqsms"
      },
      dmp: %{
        connection: :dmp,
        exchange: "service",
        queue: "dmp_update",
        routing: "dmp.update",
      }
    },
    consumers: %{
      #hits_collector: %{
        #connection: :globotunes,
        #exchange: "service",
        #queue: "users_hits_globotunes",
        #routing: "user_hits",
        #callback: Gt.Amqp.HitsCollectorConsumer
      #}
    }
  }

config :gt, :dmp,
  %{
    "150": %{
      key: "vlk",
      catalogy: "c1-ps-rm-ow",
    },
    "125": %{
      key: "vb",
      catalogy: "c1-ps-rm-ow",
    }
  }

config :gt, ecto_repos: [Gt.Repo]

config :money,
  default_currency: :USD,
  separator: ",",
  delimeter: ".",
  symbol: true,
  symbol_on_right: false,
  symbol_space: false,
  fractional_unit: false

config :arc,
  storage: Arc.Storage.Local

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
