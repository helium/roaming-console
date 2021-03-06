# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :phoenix, :json_library, Jason
# General application configuration
config :console,
  ecto_repos: [Console.Repo]

config :console,
  Console.Repo,
  migration_primary_key: [id: :uuid, type: :binary_id]

# Configures the endpoint
config :console, ConsoleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "qmS/z+jc4ZZNfmBN31tGhJbQ88aa0gD+NO8H/B5x+SCXC5XpXBAUsES7E4ubnxkJ",
  render_errors: [view: ConsoleWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Console.PubSub

config :console, :generators,
  migration: true,
  binary_id: true,
  sample_binary_id: "11111111-1111-1111-1111-111111111111"

config :console, ConsoleWeb.Guardian,
  issuer: "console",
  secret_key: "SIc3vGaukN3p6I+o/r2SEmguIhCuSRVCR3RX4w+yLDDpDpJinc7m4SsahlgmsmwK"

config :console, ConsoleWeb.AuthApiPipeline,
  module: ConsoleWeb.Guardian,
  error_handler: ConsoleWeb.AuthErrorHandler

config :hammer,
  backend: {Hammer.Backend.ETS,
            [expiry_ms: 60_000 * 60 * 4,
             cleanup_interval_ms: 60_000 * 10]}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :console,
  self_hosted: System.get_env("SELF_HOSTED")

config :console, Console.Scheduler,
  jobs: [
    refresh_materialized_views: [
      schedule: "0 * * * *", # every hour @ 0 mins
      task: {Console.Jobs, :refresh_materialized_views, []}
    ],
  ]

config :geolix,
  databases: [
    %{
      id: :geolite2_city,
      adapter: Geolix.Adapter.MMDB2,
      source: "/app/GeoLite2-City.mmdb"
    }
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
