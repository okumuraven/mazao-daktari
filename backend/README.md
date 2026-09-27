# MazaoDaktari backend

Phoenix API-only app that diagnoses crop problems from a photo and/or text
description via a rotating pool of Gemini/NVIDIA API keys. See the root
`../README.md` for the full project write-up and architecture diagram.

## Setup

```bash
mix setup        # deps.get
export GEMINI_API_KEYS="key1,key2,key3"   # comma-separated, up to 6 — optional
export NVIDIA_API_KEY="..."                # optional
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000). With no keys exported, the
API runs in **mock mode**: every `/api/diagnose` call returns a clearly
labeled sample diagnosis in the same JSON shape a live call would, so the
frontend and full flow stay testable without live API access.

Run `cp .env.example .env` for a reference of every env var this app reads,
then `export $(cat .env | xargs)` (or set them however your shell prefers —
this app doesn't load `.env` files itself; see the note in `.env.example`).

## Environment variables

| Var | Required | Default | Purpose |
|-----|----------|---------|---------|
| `GEMINI_API_KEYS` | no | — | Comma-separated Gemini API keys, rotated round-robin |
| `NVIDIA_API_KEY` | no | — | Single NVIDIA Build API key, tried after Gemini keys are exhausted |
| `GEMINI_MODEL` | no | `gemini-3.8-flash` | Override if the default is retired |
| `NVIDIA_MODEL` | no | `meta/llama-3.2-11b-vision-instruct` | Override if the default is retired |
| `PORT` | no | `4000` | HTTP port |
| `SECRET_KEY_BASE` | prod only | — | `mix phx.gen.secret` |
| `PHX_HOST` | prod only | `example.com` | Public hostname for URL generation |

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

```bash
fly launch          # auto-detects Phoenix, generates fly.toml
fly secrets set GEMINI_API_KEYS="..." NVIDIA_API_KEY="..."
fly deploy
```

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://phoenix.hexdocs.pm/overview.html
* Docs: https://phoenix.hexdocs.pm
