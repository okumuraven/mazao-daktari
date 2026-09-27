# MazaoDaktari backend

Phoenix API-only app that diagnoses crop problems from a photo and/or text
description via a rotating pool of Gemini/NVIDIA API keys. See the root
`../README.md` for the full project write-up and architecture diagram.

## Setup

Easiest: `docker compose up --build` from the repo root (see `../README.md`)
— brings up Postgres, runs migrations, and starts this app on
`localhost:4444`. The rest of this section is the non-Docker path.

Needs a local Postgres (`mix setup` runs `ecto.setup` which creates the DB
and migrates — see `config/dev.exs` for the expected credentials/port, or
override with your own).

```bash
mix setup        # deps.get + ecto.create + ecto.migrate
export GEMINI_API_KEYS="key1,key2,key3"   # comma-separated, up to 6 — optional
export NVIDIA_API_KEY="..."                # optional
export GOOGLE_CLIENT_ID="..."              # optional — needed for real Google Sign-In
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000). With no AI keys exported, the
`/api/diagnose` endpoint runs in **mock mode**: every call returns a clearly
labeled sample diagnosis in the same JSON shape a live call would, so the
frontend and full flow stay testable without live API access. Without
`GOOGLE_CLIENT_ID`, `/api/auth/google` always 401s (diagnosis itself still
works anonymously).

Run `cp .env.example .env` for a reference of every env var this app reads,
then `export $(cat .env | xargs)` (or set them however your shell prefers —
this app doesn't load `.env` files itself outside Docker; see the note in
`.env.example`).

## Environment variables

| Var | Required | Default | Purpose |
|-----|----------|---------|---------|
| `GEMINI_API_KEYS` | no | — | Comma-separated Gemini API keys, rotated round-robin |
| `NVIDIA_API_KEY` | no | — | Single NVIDIA Build API key, tried after Gemini keys are exhausted |
| `GEMINI_MODEL` | no | `gemini-3.8-flash` | Override if the default is retired |
| `NVIDIA_MODEL` | no | `meta/llama-3.2-11b-vision-instruct` | Override if the default is retired |
| `PORT` | no | `4000` | HTTP port |
| `GOOGLE_CLIENT_ID` | no | — | OAuth Web Client ID; required for `/api/auth/google` to work |
| `DATABASE_URL` | prod only | — | `ecto://user:pass@host/db` (dev/test use `config/dev.exs`/`config/test.exs` instead) |
| `SECRET_KEY_BASE` | prod only | — | `mix phx.gen.secret` |
| `PHX_HOST` | prod only | `example.com` | Public hostname for URL generation |

"Prod only" includes the Docker Compose backend — its Dockerfile sets
`MIX_ENV=prod` even for local dev (see that file's header comment for why),
so these are set in `backend/.env` for Docker, not just for a real deploy.

## API

### `GET /api/health`

```json
{ "ok": true, "mock_mode": false, "key_pool_size": 4 }
```

### `POST /api/diagnose`

`multipart/form-data` with:

- `description` (string, optional) — problem description
- `image` (file, optional) — crop photo
- `language` (`"en"` | `"sw"`, optional, defaults to `"en"`)

At least one of `description`/`image` is required (400 if both are empty).

```json
{
  "mock": false,
  "crop": "Maize",
  "issue": "Gray Leaf Spot (Cercospora zeae-maydis)",
  "confidence": "medium",
  "symptoms": ["..."],
  "treatment": ["..."],
  "prevention": ["..."],
  "urgency": "high",
  "language": "en"
}
```

If the request carries a valid `Authorization: Bearer <token>` (see below),
the diagnosis is also saved to that user's history. Anonymous requests are
diagnosed the same way but never persisted.

### `POST /api/auth/google`

Body: `{"credential": "<Google ID token>"}` — the credential the frontend
gets directly from Google Identity Services after sign-in. Verifies it
against Google's `tokeninfo` endpoint, upserts the user, and returns:

```json
{ "token": "<opaque session token>", "user": { "id": 1, "email": "...", "name": "...", "avatar_url": "..." } }
```

Send that `token` back as `Authorization: Bearer <token>` on subsequent
requests. 401s on an invalid/expired Google credential or if
`GOOGLE_CLIENT_ID` isn't configured.

### `GET /api/me` (requires auth)

Returns `{"user": {...}}` for the signed-in user — used by the frontend to
restore a session after a page reload. 401 without a valid token.

### `GET /api/diagnoses` (requires auth)

Returns `{"diagnoses": [...]}`, most recent first, for the signed-in user.
401 without a valid token.

## AI key rotation (`MazaoDaktari.AI.KeyRing`)

A supervised `GenServer` (started in `MazaoDaktari.Application`) builds a
pool of `%{provider, key}` entries from `GEMINI_API_KEYS` +
`NVIDIA_API_KEY` at boot. `MazaoDaktari.CropDiagnosis.diagnose/4`:

1. Checks out the next entry in round-robin order (`KeyRing.checkout/1`).
2. Calls that provider's `diagnose/5` (`MazaoDaktari.AI.Providers.Gemini` or
   `.Nvidia`, both implementing the `MazaoDaktari.AI.Provider` behaviour).
3. On `{:error, :rate_limited}` (HTTP 429), puts that entry in a 60s
   cooldown (`KeyRing.report_rate_limited/2`) and retries the next entry.
4. On any other error, also moves to the next entry rather than failing the
   request outright.
5. Once every configured entry has been tried (or the pool is empty),
   returns the mock diagnosis.

It's a `GenServer` rather than an `Agent`/ETS table specifically so the
round-robin cursor advances atomically under concurrent requests — two
simultaneous diagnoses must never be handed the stale/same cursor position.

Tests: `test/mazao_daktari/ai/key_ring_test.exs` covers round-robin order,
cooldown skip/expiry, and the empty-pool case, using a per-test named
instance (`start_supervised!({KeyRing, pool: [...], name: :unique_name})`)
isolated from the app's own singleton `KeyRing` process.

## CORS

`CORSPlug`'s `init/1` bakes `origin:` in at **compile time** (standard
Plug/Phoenix plug-opts behavior), so the allowed frontend origin(s) must be
literal `config :cors_plug, origin: [...]` values in `config/dev.exs` /
`config/prod.exs` — not a runtime env var lookup. Update
`config/prod.exs` with the real Vercel domain once the frontend is deployed.

## Deployment (Fly.io)

**Live at https://mazao-daktari-api.fly.dev** (app: `mazao-daktari-api`, org:
`personal`, region: `jnb`).

The `Dockerfile` in this directory is the **local dev** image (bind-mounted
source, recompiles from source each start). `Dockerfile.fly` is the actual
deploy image (multi-stage, compiled OTP release, generated via
`mix phx.gen.release --docker` then moved aside so it doesn't collide with
the dev one — matches the LisangaConnect project's convention of keeping
the two separate). `fly.toml` points `[build] dockerfile` at it.

`fly.toml` also sets `ECTO_IPV6 = 'true'` — Fly's internal Postgres network
(`.flycast`/`.internal`) is IPv6-only, and without this the BEAM's own DNS
resolver fails to connect with `:nxdomain` even though the hostname
resolves fine at the platform level (confirmed live: `fly ssh console` +
`getent hosts` resolved it; only the running app's Postgrex connections
failed, until this was set). `config/runtime.exs` reads it to add
`socket_options: [:inet6]` to the Repo config.

`[deploy] release_command = '/app/bin/migrate'` in `fly.toml` runs
migrations automatically before each new version goes live.

To redeploy after changes:

```bash
fly deploy --app mazao-daktari-api
```

To set up a fresh instance elsewhere (a new Fly account/org, for example):

```bash
fly launch --dockerfile Dockerfile.fly --db=true --no-deploy   # provisions Postgres, writes fly.toml
fly secrets set GEMINI_API_KEYS="..." NVIDIA_API_KEY="..." GOOGLE_CLIENT_ID="..." SECRET_KEY_BASE="$(mix phx.gen.secret)"
fly deploy
```

`DATABASE_URL` is set automatically when `fly launch --db` attaches
Postgres — no need to set it by hand.

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://phoenix.hexdocs.pm/overview.html
* Docs: https://phoenix.hexdocs.pm
