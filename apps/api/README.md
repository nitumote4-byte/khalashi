# @khalashi/api

Node (Express + TypeScript) API for Khalashi — auth + trips + bookings + soft-launch harden.

## Endpoints

| Method | Path | Notes |
|--------|------|-------|
| GET | `/health` | Liveness |
| POST | `/auth/otp/request` | `{ "phone": "98XXXXXXXX" }` — rate limited |
| POST | `/auth/otp/verify` | upserts user in Postgres; returns Bearer token |
| GET | `/auth/me` | Bearer |
| POST | `/auth/logout` | Bearer |
| POST | `/trips` | Offer a ride — `{ origin, destination, pickupPoint?, dropoffPoint?, departAt, seatsTotal, fareInr, carModel, numberPlate, carColor }` — rate limited + spam guards |
| GET | `/trips/mine` | Driver trips |
| GET | `/trips/search` | `origin`, `destination`, `date=YYYY-MM-DD`, optional `pickupPoint` / `dropoffPoint` (loose ILIKE) — rate limited |
| GET | `/trips/:id` | Detail |
| POST | `/trips/:id/cancel` | Free cancel until start; cascades bookings |
| GET | `/trips/:id/bookings` | Driver booking list |
| POST | `/trips/:id/bookings` | `{ seats, seatPreference }` — rate limited |
| GET | `/bookings/mine` | Traveller bookings |
| GET | `/bookings/:id` | Detail |
| POST | `/bookings/:id/cancel` | Free cancel until start; restores seats |

Seat booking uses a row lock (`FOR UPDATE`) so concurrent requests cannot oversell.

Errors: `{ "ok": false, "error": "...", "code": "RATE_LIMITED" | "SEATS_FULL" | ... }`.

## Soft-launch guards

- OTP request: per-phone + per-IP sliding windows
- Search / book / trip-post: per-user windows (`RATE_LIMIT_*`)
- Trip spam: max trips per driver per 24h; block duplicate open trip same route + IST day; min depart ahead minutes
- Request logs: JSON lines with method/path/status/ms (no OTP bodies)

## OTP providers

Set `OTP_PROVIDER` in `.env` (default **`mock`** for local/dev):

| Value | Behavior |
|-------|----------|
| `mock` | Logs OTP; returns `debugCode`; optional `OTP_MOCK_CODE=123456` |
| `msg91` | Sends SMS via MSG91 OTP API v5 with our generated code; verify stays local |
| `2factor` | Stub until wired; requires `TWO_FACTOR_API_KEY` |

**MSG91 required env** (when `OTP_PROVIDER=msg91`): `MSG91_AUTH_KEY`, `MSG91_TEMPLATE_ID`, `MSG91_SENDER_ID`. Missing any → `503` / `OTP_PROVIDER_MISCONFIGURED`.

**Secrets:** never commit real keys. Use local `.env`, Cursor Environment Secrets, or GitHub Actions secrets under those exact names. See root README + `.env.example` for India DLT notes.

OTP challenges + sessions stay in-memory; **users/trips/bookings require Postgres**.

## Setup

```bash
cp .env.example .env
npm install
npm run migrate
npm run dev
```

Smoke:

- `./scripts/smoke-otp.sh` — mock OTP + msg91 misconfig (starts its own processes)
- `./scripts/smoke-phase2.sh` — trip/book/cancel (API on :3000)
- `./scripts/smoke-phase3.sh` — rate limits + spam codes (API on :3000)

## Deploy

Container image: `Dockerfile` + `docker-entrypoint.sh` (migrations then `node dist/index.js`).

Host configs: `railway.toml`, `fly.toml` (this folder); repo-root `render.yaml` Blueprint.

Soft-launch env: `OTP_PROVIDER=mock`, `DATABASE_URL`, `SESSION_SECRET` (host secrets only). See root README **Deploy** section for Flutter `API_BASE_URL` and agent token unblock steps.
