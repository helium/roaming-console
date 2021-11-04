use Mix.Config

config :console, ConsoleWeb.Endpoint,
  load_from_system_env: true,
  url: [scheme: "https", host: System.get_env("HOSTNAME"), port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

config :logger, level: :info

config :console, Console.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

config :console, ConsoleWeb.Guardian,
  issuer: "console",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY")

config :console, Console.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: "mg2.helium.com"

config :console,
  router_secrets: String.split(System.get_env("ROUTER_SECRETS"), ",")

config :console,
  magic_secret_key: System.get_env("MAGIC_SECRET_KEY")

config :appsignal, :config,
  active: true,
  name: System.get_env("APPSIGNAL_APP_NAME"),
  push_api_key: System.get_env("APPSIGNAL_API_KEY"),
  env: Mix.env

config :console,
  stripe_secret_key: System.get_env("STRIPE_SECRET_KEY")
