defmodule Gt.Mixfile do
  use Mix.Project

  def project do
    [app: :gt,
     version: "0.0.1",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Gt, []},
      applications: applications(Mix.env)
    ]
  end

  def applications(env) when env in [:test] do
    applications(:default) ++ [:ex_machina]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def applications (_) do
    [:phoenix,
     :phoenix_html,
     :cowboy,
     :logger,
     :gettext,
     :phoenix_ecto,
     :postgrex,
     :comeonin,
     :ueberauth,
     :timex,
     :amqp,
     :ueberauth_identity,
     :arc_ecto,
     :httpotion,
     :iconv,
     :mailroom,
     :export,
     :redix]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.1"},
     {:phoenix_ecto, "~> 3.2.1"},
     {:postgrex, "~> 0.13.0"},
     {:phoenix_html, "~> 2.9.1"},
     {:phoenix_live_reload, "~> 1.0.6", only: :dev},
     {:guardian_db, "~> 0.8.0"},
     {:ueberauth, "~> 0.4.0"},
     {:ueberauth_identity, "~> 0.2.3"},
     {:gettext, "~> 0.13"},
     {:ecto, "~> 2.1"},
     {:cowboy, "~> 1.0"},
     {:comeonin, "~> 3.0"},
     {:pot, "~> 0.9.5"},
     {:parallel_stream, "~> 1.0"},
     {:ex_machina, "~> 1.0", only: [:dev, :test]},
     {:timex, "~> 3.0"},
     {:navigation_history, "~> 0.2.0"},
     {:kerosene, "~> 0.5.0"},
     {:amqp, "~> 0.1.5"},
     {:amqp_client, github: "jbrisbin/amqp_client", ref: "d50aec0", override: true},
     {:rabbit_common, git: "https://github.com/Nezteb/rabbit_common.git", override: true},
     {:exoffice, github: "alexkovalevych/exoffice"},
     {:money, "~> 1.2"},
     {:html_sanitize_ex, "~> 1.1"},
     {:arc_ecto, "~> 0.5.0"},
     {:sweet_xml, "~> 0.6.5"},
     {:httpotion, "~> 3.0"},
     {:floki, "~> 0.14.0"},
     {:mochiweb, "~> 2.12.2", override: true},
     {:iconv, "~> 1.0"},
     {:mailroom, github: "andrewtimberlake/mailroom", branch: "master"},
     {:xlsxir, github: "alexkovalevych/xlsxir", branch: "parallel-support", override: true},
     {:redix, ">= 0.0.0"},
     {:elixlsx, "~> 0.1.1"},
     {:export, "~> 0.1.0"},
    ]
  end

  # Aliases are shortcut or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     test: [&setup_db/1, "test"],
     translations: [
        "gettext.extract --merge",
        "gettext.merge priv/gettext --locale en",
        "run -e 'Mix.Task.reenable(\"gettext.merge\")'",
        "gettext.merge priv/gettext --locale ru"
      ],
    ]
  end

  defp setup_db(_) do
    # Create the database, run migrations
    Mix.Task.run "ecto.drop"#, ["--quiet"]
    Mix.Task.run "ecto.create"#, ["--quiet"]
    Mix.Task.run "ecto.migrate"#, ["--quiet"]
  end

end
