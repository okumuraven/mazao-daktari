# Mazao Daktari (Crop Doctor)

Mobile-first web app built for GoMyCode's **"Come Build with AI"** hackathon —
Kenya track, targeting the **Click Mobile Mobile-First Impact Award**.

A farmer photographs (or describes) a sick crop from their phone. The app
diagnoses the likely pest/disease/deficiency and returns practical,
locally-actionable treatment and prevention advice — in English or Swahili.
Signing in with Google saves a farmer's diagnosis history; the diagnosis
feature itself works fully anonymously too.

## Problem

Smallholder farmers in Kenya often lack fast, affordable access to an
agronomist when a crop problem appears. A wrong or delayed diagnosis can cost
a season's yield. Most diagnostic tools assume reliable connectivity, a
smartphone app install, and English-only output — all friction points for
the actual target user.

## Solution

A single-page, low-bandwidth mobile web app (no install, opens straight in
the browser) that takes a photo and/or a short text description and returns
a structured diagnosis: crop, issue, confidence, urgency, symptoms matched,
treatment steps, and prevention tips — localized to English or Swahili.

## Architecture

```
┌─────────────────────┐        HTTPS/JSON        ┌──────────────────────────┐
│  Next.js frontend    │ ────────────────────────▶│  Phoenix (Elixir) API    │
│  (Vercel)             │◀──────────────────────── │  (Fly.io)                │
│  - mobile-first form  │  diagnosis / auth JSON    │  - POST /api/diagnose    │
│  - EN/SW toggle       │                           │  - POST /api/auth/google│
│  - Google Sign-In     │                           │  - GET  /api/me         │
└─────────────────────┘                           │  - GET  /api/diagnoses  │
                                                    │  - GET  /api/health     │
                                                    └──────┬────────────┬─────┘
                                                            │            │
                                                round-robin,│            │
                                                cooldown 429│            ▼
                                                            ▼      Postgres
                                              ┌──────────────────────────┐   (users, diagnoses)
                                              │  MazaoDaktari.AI.KeyRing │
                                              │  (GenServer)             │
                                              └────────────┬─────────────┘
                                                            │
                                         ┌──────────────────┴──────────────────┐
                                         ▼                                     ▼
                               Gemini (up to 6 keys)                  NVIDIA Build (1 key)
                               gemini-3.8-flash, multimodal           meta/llama-3.2-11b-vision-instruct
```

Google Sign-In (`MazaoDaktari.Accounts`) verifies the ID token the frontend
gets from Google Identity Services against Google's `tokeninfo` endpoint,
upserts a `users` row, and issues an opaque `Phoenix.Token` session token.
Diagnosis history is only ever saved for a signed-in request — anonymous
diagnoses are never persisted.

### Why a key rotation pool

Free-tier AI API keys carry per-key rate limits well below what a live demo
plus judge testing can produce in a short window. Rather than depend on a
single key (and go down the moment it's throttled), the backend holds a pool
of up to 6 Gemini keys plus one NVIDIA Build key and round-robins across
them:

1. A request checks out the next non-cooled-down pool entry.
2. On a 429 from that provider, the entry is put in a 60s cooldown and the
   request retries the next pool entry — up to once per configured key.
3. If every entry is exhausted (or none are configured), the API returns a
   **clearly-labeled mock diagnosis** in the exact same JSON shape as a live
   one, so the frontend and the demo never hard-fail.

See `backend/lib/mazao_daktari/ai/key_ring.ex` for the implementation and
`backend/test/mazao_daktari/ai/key_ring_test.exs` for its test coverage.

## Tech stack

| Layer    | Choice                          | Why |
|----------|----------------------------------|-----|
| Frontend | Next.js (App Router) + Tailwind  | Mobile-first + real desktop layout, deployed to Vercel |
| Backend  | Phoenix (Elixir), API-only       | JSON API, deployed to Fly.io |
| Database | Postgres + Ecto                  | Accounts + diagnosis history |
| Auth     | Google Identity Services (frontend) + `tokeninfo` verification (backend) | No password path; `Phoenix.Token` for the app's own session |
| AI       | Gemini (`gemini-3.8-flash`) + NVIDIA Build fallback | Multimodal (photo + text) diagnosis, key-rotated across free tiers |
| HTTP client (backend) | `Req`                | Project convention (see `backend/AGENTS.md`) — not httpoison/tesla/httpc |
| Icons    | `lucide-react`                   | SVG icons, no emoji |

## Repo layout

```
mazao-daktari/
├── frontend/   Next.js app (Vercel)
├── backend/    Phoenix API (Fly.io)
└── README.md   this file
```

## Local development

### Docker (recommended — runs the whole stack in one command)

```bash
cp backend/.env.example backend/.env       # fill in at least GEMINI_API_KEYS
docker compose up --build
```

This starts Postgres (`localhost:5433`), the Phoenix API (`localhost:4444`,
runs `mix ecto.migrate` on boot), and the Next.js frontend
(`localhost:3333`), all bind-mounted for live reload. See the root
`docker-compose.yml` and each service's `Dockerfile` for the exact setup —
the backend intentionally runs under `MIX_ENV=prod` even locally (see that
Dockerfile's header comment for why), so `backend/config/prod.exs`'s CORS
origin list already includes `http://localhost:3333`.

### Without Docker

**Backend** (needs a local Postgres — see `backend/README.md` for full
detail):

```bash
cd backend
export GEMINI_API_KEYS="key1,key2,..."   # optional — omit for mock mode
export NVIDIA_API_KEY="..."               # optional
mix setup
mix phx.server
```

**Frontend**:

```bash
cd frontend
cp .env.example .env.local   # set NEXT_PUBLIC_API_URL to the backend's URL
npm install
npm run dev
```

## Deployment

- **Frontend → Vercel**: standard Next.js deploy; set `NEXT_PUBLIC_API_URL`
  to the deployed Fly.io backend URL in Vercel's environment variables.
- **Backend → Fly.io**: `fly launch` (Phoenix is auto-detected), then set
  secrets with `fly secrets set GEMINI_API_KEYS=... NVIDIA_API_KEY=...`.
  Update `backend/config/prod.exs`'s `:cors_plug, :origin` list with the
  real Vercel domain once assigned — CORSPlug bakes this in at compile
  time, so it can't be read from a runtime env var (see the comment in that
  file for the full reasoning).

## AI / tool disclosure (for hackathon submission)

- **Models**: Google Gemini (`gemini-3.8-flash` by default, multimodal) as
  primary, NVIDIA Build (`meta/llama-3.2-11b-vision-instruct` by default) as
  a rotation fallback. Both configurable via env vars.
- **AI contribution**: the model performs the actual crop diagnosis —
  reading the uploaded photo and/or text description and producing the
  issue/confidence/treatment/prevention output shown to the user. This is
  the core feature, not a cosmetic add-on.
- **Access constraint / fallback**: requires at least one configured key.
  With none configured, or if the entire rotation pool is temporarily
  rate-limited, the API serves a clearly-labeled mock response in the same
  JSON shape, so functional execution can still be demonstrated.
- **NVIDIA Brev**: not used (no GPU training/hosting need — inference only,
  against hosted APIs).
- **Data**: photos/descriptions are sent to the AI provider for inference
  only; nothing is persisted by this app (no database).

## Live

- Backend: https://mazao-daktari-api.fly.dev
- Frontend: https://frontend-theta-nine-46.vercel.app

## Next steps

- Lightweight feedback loop (farmer confirms/corrects the diagnosis) to
  build a small labeled dataset for future fine-tuning.
- SMS/USSD fallback for farmers without smartphones.
- Set `GOOGLE_CLIENT_ID` (backend secret) and `NEXT_PUBLIC_GOOGLE_CLIENT_ID`
  (Vercel env var) once the Google Cloud Console OAuth client is created —
  Google Sign-In fails cleanly without it, everything else works.
