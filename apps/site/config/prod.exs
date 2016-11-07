use Mix.Config

# For production, we configure the host to read the PORT
# from the system environment. Therefore, you will need
# to set PORT=80 before running your server.
#
# You should also configure the url host to something
# meaningful, we use this information when generating URLs.
#
# Finally, we also include the path to a manifest
# containing the digested version of static files. This
# manifest is generated by the mix phoenix.digest task
# which you typically run after static files are built.
config :site, Site.Endpoint,
  http: [port: {:system, "PORT"}, compress: true],
  url: [host: {:system, "HOST"}, port: 80],
  static_url: [
    scheme: {:system, "STATIC_SCHEME"},
    host: {:system, "STATIC_HOST"},
    port: {:system, "STATIC_PORT"}
  ],
  cache_static_manifest: "priv/static/manifest.json"

# Do not print debug messages in production
config :logger,
  level: :debug,
  backends: [{Logger.Backend.Logentries, :logentries}, :console]

config :logger, :logentries,
  connector: Logger.Backend.Logentries.Output.SslKeepOpen,
  host: 'data.logentries.com',
  port: 443,
  token: "${LOGENTRIES_TOKEN}",
  format: "$dateT$time [$level]$levelpad node=$node $metadata$message\n",
  metadata: [:request_id]

  # ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :site, Site.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
config :site, Site.Endpoint,
  force_ssl: [
    rewrite_on: [:x_forwarded_proto]
  ]

# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :site, Site.Endpoint, server: true
#
# You will also need to set the application root to `.` in order
# for the new static assets to be served after a hot upgrade:
#

config :site, Site.ViewHelpers,
  google_api_key: "${GOOGLE_API_KEY}",
  google_tag_manager_id: "${GOOGLE_TAG_MANAGER_ID}"

config :site, GoogleMaps,
  client_id: "${GOOGLE_MAPS_CLIENT_ID}",
  signing_key: "${GOOGLE_MAPS_SIGNING_KEY}"

config :ehmon, :report_mf, {:ehmon, :info_report}
