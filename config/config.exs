# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :niex, NiexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "jL1VNnAUnm8tgEOpFHRMSdsauPfQ2R/8CPSvu8lphKkvRERimswb4Y1RupHkVasq",
  render_errors: [view: NiexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Niex.PubSub,
  live_view: [signing_salt: "TcaKZjCh"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Poison

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
