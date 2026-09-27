import Config

# CORSPlug's init/1 bakes `origin:` in at compile time, so this must be a
# literal list here (not read from an env var), same reasoning as
# LisangaConnect's backend/config/prod.exs. Update the Vercel URL below once
# the frontend is deployed and its real domain is known.
config :cors_plug,
  origin: [
    "https://frontend-theta-nine-46.vercel.app",
    "http://localhost:3000",
    # frontend's docker-compose dev port (see root docker-compose.yml) -
    # this file is what the local Docker backend actually compiles under
    # too, since its Dockerfile sets MIX_ENV=prod (see that Dockerfile's
    # header comment for the full reasoning)
    "http://localhost:3333"
  ]

# Force using SSL in production. This also sets the "strict-security-transport" header,
# known as HSTS. If you have a health check endpoint, you may want to exclude it below.
# Note `:force_ssl` is required to be set at compile-time.
config :mazao_daktari, MazaoDaktariWeb.Endpoint,
  force_ssl: [
    rewrite_on: [:x_forwarded_proto],
    exclude: [
      # paths: ["/health"],
      hosts: ["localhost", "127.0.0.1"]
    ]
  ]

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
