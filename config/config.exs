# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :keja_digital,
  ecto_repos: [KejaDigital.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :keja_digital, KejaDigitalWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: KejaDigitalWeb.ErrorHTML, json: KejaDigitalWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: KejaDigital.PubSub,
  live_view: [signing_salt: "NaN881MN"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :keja_digital, KejaDigital.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  keja_digital: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  keja_digital: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :keja_digital, :mpesa,
  consumer_key: "hoi93y89r893u1ihf9fhqhhqyfyfqfjf",
  consumer_secret: "dbnwnbwhhwh36i322gdwbjkdjwwjkwd",
  base_url: "https://sandbox.safaricom.co.ke"


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :keja_digital, :mpesa,
  consumer_key: System.get_env("MPESA_CONSUMER_KEY"),
  consumer_secret: System.get_env("MPESA_CONSUMER_SECRET"),
  passkey: System.get_env("MPESA_PASSKEY"),
  business_short_code: System.get_env("MPESA_BUSINESS_SHORT_CODE"),
  callback_url: System.get_env("MPESA_CALLBACK_URL")
