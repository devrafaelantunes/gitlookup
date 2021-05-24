# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config


config :git_lookup,
  ecto_repos: [GitLookup.Repo]

# Configures the endpoint
config :git_lookup, GitLookupWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QOv+1mpHkrwUag1xf7S9yH5cEeBmy3dfEmWBB+Z9S2i5dQd66X2tAjdrAd4elFLg",
  render_errors: [view: GitLookupWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: GitLookup.PubSub,
  live_view: [signing_salt: "XSQmBwgz"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
