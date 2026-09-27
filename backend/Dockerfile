# Local dev image - mirrors LisangaConnect's own backend/Dockerfile pattern
# (single stage, whole app copied in, deps fetched at build time,
# `mix ecto.migrate && mix phx.server` on start). Relies on
# docker-compose's bind mount over /app for live code, and on
# `network: host` (see the build block in the root docker-compose.yml)
# for build-time Hex/rebar access.
#
# MIX_ENV=prod even for local dev: this means the container compiles
# and runs under config/prod.exs + config/runtime.exs, not config/dev.exs
# - notably the CORS origin allowlist (backend/config/prod.exs) and the
# DATABASE_URL/SECRET_KEY_BASE requirement (backend/config/runtime.exs)
# apply here too. Matches LisangaConnect's backend/config/prod.exs comment
# for the identical reasoning: this file is what local Docker dev actually
# compiles under, not just what production uses.
FROM elixir:1.18

RUN apt-get update && apt-get install -y build-essential inotify-tools postgresql-client && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV HEX_HTTP_TIMEOUT=120 \
    HEX_HTTP_CONCURRENCY=1 \
    HEX_MIRROR="https://repo.hex.pm" \
    HEX_BUILDS_URL="https://repo.hex.pm" \
    MIX_ENV=prod \
    MIX_REBAR3=/usr/local/bin/rebar3

RUN mix local.hex --force && mix local.rebar --force

COPY . .
RUN mix deps.get && mix deps.compile
RUN mix compile

CMD mix ecto.migrate && mix phx.server
