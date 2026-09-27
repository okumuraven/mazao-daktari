# MazaoDaktari frontend

Mobile-first Next.js app (App Router). See the root `../README.md` for the
full project write-up and architecture diagram.

## Setup

```bash
cp .env.example .env.local   # set NEXT_PUBLIC_API_URL to the backend's URL
npm install
npm run dev
```

Open http://localhost:3123 (or whatever port you pass to `next dev -p`).

## Environment variables

| Var | Required | Default | Purpose |
|-----|----------|---------|---------|
| `NEXT_PUBLIC_API_URL` | no | `http://localhost:4000` | Base URL of the Phoenix backend |

## Structure

- `app/page.tsx` — the single-page UI: language toggle, description/photo
  inputs, submit, result card.
- `lib/strings.ts` — English/Swahili copy.
- `lib/diagnosis.ts` — typed `fetch` call to `POST /api/diagnose` on the
  backend.

No routing beyond the single page; no state persisted beyond the current
session (each diagnosis is a fresh request).

## Deployment (Vercel)

Standard Next.js deploy. Set `NEXT_PUBLIC_API_URL` in Vercel's project
environment variables to the deployed Fly.io backend's URL, then update the
backend's `config/prod.exs` CORS origin list with the assigned Vercel
domain (see `../backend/README.md#cors`).

## Learn more

- [Next.js Documentation](https://nextjs.org/docs)
