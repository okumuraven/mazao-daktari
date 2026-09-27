# Mazao Daktari (Crop Doctor)

Mobile-first web app built for GoMyCode's **"Come Build with AI"** hackathon —
Kenya track, targeting the **Click Mobile Mobile-First Impact Award**.

A farmer photographs (or describes) a sick crop from their phone. The app
diagnoses the likely pest/disease/deficiency and returns practical,
locally-actionable treatment and prevention advice — in English or Swahili.

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
│  - mobile-first form  │      diagnosis JSON       │  - POST /api/diagnose    │
│  - EN/SW toggle       │                           │  - GET  /api/health      │
└─────────────────────┘                           └────────────┬─────────────┘
                                                                 │
                                                    round-robin, │ cooldown on 429
                                                                 ▼
                                                   ┌──────────────────────────┐
                                                   │  MazaoDaktari.AI.KeyRing │
                                                   │  (GenServer)             │
                                                   └────────────┬─────────────┘
                                                                 │
                                              ┌──────────────────┴──────────────────┐
                                              ▼                                     ▼
                                    Gemini (up to 6 keys)                  NVIDIA Build (1 key)
                                    gemini-3.8-flash, multimodal           meta/llama-3.2-11b-vision-instruct
```

No database — the app is stateless; every request is diagnosed independently
and nothing is persisted server-side.

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
| Frontend | Next.js (App Router) + Tailwind  | Mobile-first form + result view, deployed to Vercel |
| Backend  | Phoenix (Elixir), API-only       | JSON API, deployed to Fly.io |
| AI       | Gemini (`gemini-3.8-flash`) + NVIDIA Build fallback | Multimodal (photo + text) diagnosis, key-rotated across free tiers |
| HTTP client (backend) | `Req`                | Project convention (see `backend/AGENTS.md`) — not httpoison/tesla/httpc |

## Repo layout

```
mazao-daktari/
├── frontend/   Next.js app (Vercel)
├── backend/    Phoenix API (Fly.io)
└── README.md   this file
```

## Local development

**Backend** (see `backend/README.md` for full detail):

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

## Next steps

- Lightweight feedback loop (farmer confirms/corrects the diagnosis) to
  build a small labeled dataset for future fine-tuning.
- SMS/USSD fallback for farmers without smartphones.
- Persist diagnosis history per farmer (would introduce the first database).
