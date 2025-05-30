import Config

config :kobrakai, Kobrakai.Blog, show_drafts: true
config :kobrakai, Kobrakai.Portfolio, show_drafts: true

config :kobrakai, :image_plug_cache,
  max_age: {1, :hour},
  stale_while_revalidate: {20, :minutes}

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :kobrakai, KobrakaiWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "5x0q0Y1j1FKgBNGfJmjjOY6qj/GEX7U8EsZWtonVrXIfVaFhcNk4Fg54oXHdX9R2",
  watchers: [
    bun: {Bun, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    serviceworker: {Bun, :install_and_run, [:serviceworker, ~w(--sourcemap=inline --watch)]},
    bun_css: {Bun, :install_and_run, [:css, ~w(--watch)]},
    bun_storybook: {Bun, :install_and_run, [:storybook, ~w(--watch)]}
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :kobrakai, KobrakaiWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/kobrakai_web/(controllers|live|components|views)/.*(ex|heex)$",
      ~r"posts/*/.*(md)$",
      ~r"storybook/.*(exs)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :kobrakai, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Disable admin access control
config :kobrakai, :admin, false

# Configure image plug
config :kobrakai, KobrakaiWeb, secret_key: "abc"

# Configure bold integration
config :kobrakai, Kobrakai.Bold, api_key: System.get_env("BOLD_API_KEY")
