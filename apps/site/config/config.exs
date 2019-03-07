# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :site, SiteWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4DTl03knjPRXF9QYrTqcVRZUy8hN5gS6x6rN1mIImpo1rcN79d77ZAfShyVqDzx/",
  render_errors: [accepts: ~w(html), layout: {SiteWeb.LayoutView, "app.html"}],
  pubsub: [name: Site.PubSub, adapter: Phoenix.PubSub.PG2]

config :phoenix, :gzippable_exts, ~w(.txt .html .js .css .svg)

# Configures Elixir's Logger
config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  metadata: [:request_id]

# Include referrer in Logster request log
config :logster, :allowed_headers, ["referer"]

config :site, SiteWeb.ViewHelpers, google_tag_manager_id: System.get_env("GOOGLE_TAG_MANAGER_ID")

config :laboratory,
  features: [],
  cookie: [
    # one month,
    max_age: 3600 * 24 * 30,
    http_only: true
  ]

config :site, Site.BodyTag, mticket_header: "x-mticket"

# Centralize Error reporting
config :sentry,
  dsn: System.get_env("SENTRY_DSN") || "",
  environment_name: Mix.env(),
  enable_source_code_context: false,
  root_source_code_path: File.cwd!(),
  included_environments: [:prod, :dev],
  json_library: Poison

config :site, :former_mbta_site, host: "http://old.mbta.com"

config :site, OldSiteFileController,
  response_fn: {SiteWeb.OldSiteFileController, :send_file},
  gtfs_s3_bucket: {:system, "GTFS_S3_BUCKET", "mbta-gtfs-s3"}

config :site, StaticFileController, response_fn: {SiteWeb.StaticFileController, :send_file}

config :util,
  router_helper_module: {:ok, SiteWeb.Router.Helpers},
  endpoint: {:ok, SiteWeb.Endpoint}

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

config :site, :react,
  source_path: Path.join(File.cwd!(), "/apps/site/react_renderer/"),
  build_path: Path.join(File.cwd!(), "/apps/site/react_renderer/dist/app.js")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
