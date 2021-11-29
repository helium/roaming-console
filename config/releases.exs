import Config

config :logger, level: :info

secret_key_base = System.get_env("SECRET_KEY_BASE") ||
  raise """
  environment variable SECRET_KEY_BASE is missing.
  You can generate one by calling: mix phx.gen.secret
  """
config :console, ConsoleWeb.Endpoint,
  server: true,
  url: [host: "localhost"],
  cache_static_manifest: "priv/static/cache_manifest.json",
  http: [:inet6, port: 4000],
  secret_key_base: secret_key_base

db_host = System.get_env("DATABASE_HOST") ||
  raise """
  environment variable DATABASE_HOST is missing.
  """
config :console, Console.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("DATABASE_USER") || "postgres",
  password: System.get_env("DATABASE_PASSWORD") || "postgres",
  database: System.get_env("DATABASE_DB") || "console_dev",
  hostname: db_host,
  pool_size: 10

config :console, ConsoleWeb.Guardian,
  issuer: "console",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY")

config :console,
  packet_purchaser_secrets: String.split(System.get_env("PACKET_PURCHASER_SECRETS"), ",")

config :console,
  self_hosted: true

config :console,
  mapbox_pk: System.get_env("MAPBOX_PRIVATE_KEY")

config :console,
  mapbox_style_url: System.get_env("MAPBOX_STYLE_URL")

config :console, Console.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("SITE_DOMAIN_MAILGUN"),
  base_uri: System.get_env("MAILGUN_URL") || "https://api.mailgun.net/v3"
