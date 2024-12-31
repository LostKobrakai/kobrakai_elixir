# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :kobrakai, Kobrakai.Blog, show_drafts: false
config :kobrakai, Kobrakai.Portfolio, show_drafts: false

# Configures the endpoint
config :kobrakai, KobrakaiWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: KobrakaiWeb.ErrorHTML, json: KobrakaiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Kobrakai.PubSub,
  live_view: [signing_salt: "Rtah5aPu"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :kobrakai, Kobrakai.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :bun,
  version: "1.1.34",
  install: [args: ~w(install), cd: Path.expand("../assets", __DIR__), env: %{}],
  default: [
    args:
      ~w(build js/app.js js/storybook.js js/video.js js/serviceworker.js --format=iife --outdir=../priv/static/assets --external /fonts/* --external /images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{}
  ],
  css: [
    args: ~w(run tailwindcss --input=css/app.css --output=../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__),
    env: %{}
  ],
  storybook: [
    args:
      ~w(run tailwindcss --input=css/storybook.css --output=../priv/static/assets/storybook.css),
    cd: Path.expand("../assets", __DIR__),
    env: %{}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Custom mime types
config :mime, :types, %{
  "application/jrd+json" => ["jrd"]
}

# Schedule quantum
config :kobrakai, Kobrakai.Quantum.Scheduler,
  jobs: [
    {"@reboot", {Kobrakai.CV, :refresh_elixir_forum_stats, []}},
    {"@daily", {Kobrakai.CV, :refresh_elixir_forum_stats, []}}
  ]

config :kobrakai, :image_plug_cache,
  max_age: {24, :hour},
  stale_while_revalidate: {12, :hour}

# Use improved compressors
config :phoenix,
  static_compressors: [
    PhoenixBakery.Gzip,
    PhoenixBakery.Zstd
  ]

config :reverse_proxy_plug,
  http_client: ReverseProxyPlug.HTTPClient.Adapters.Req

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
