# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :mrgr, :env, "dev"

config :mrgr,
  ecto_repos: [Mrgr.Repo]

config :mrgr, Mrgr.Repo, migration_timestamps: [type: :utc_datetime]

# Configures the endpoint
config :mrgr, MrgrWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "u3FKQ+uYmNwImJ1JJwnt4mh+Tx8d6uNs37lhJTiBprXNOckEcvOzQ0sbZis6828k",
  render_errors: [view: MrgrWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Mrgr.PubSub,
  live_view: [signing_salt: "pI9GZU9j"]

config :mrgr, :installation, url: "https://github.com/apps/mrgr-development/installations/new"
# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :mrgr, Mrgr.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :mrgr, :oauth,
  client_id: System.get_env("GITHUB_OAUTH_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_OAUTH_CLIENT_SECRET")

config :mrgr, :github, implementation: Mrgr.Github.API.Live

config :joken,
  rs256: [
    signer_alg: "RS256",
    key_pem: System.get_env("GITHUB_PRIVATE_KEY")
  ]

config :tailwind,
  version: "3.1.4",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :ex_heroicons, type: "outline"

config :mrgr, Oban,
  repo: Mrgr.Repo,
  plugins: [Oban.Plugins.Pruner, Oban.Plugins.Gossip, Oban.Web.Plugins.Stats],
  queues: [default: 10]

import_config "#{config_env()}.exs"

import_config "appsignal.exs"
