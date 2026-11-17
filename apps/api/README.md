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
| POST | `/trips` | Offer a ride — `{ origin, destination, departAt, seatsTotal, fareInr, carModel, numberPlate, carColor }` — rate limited + spam guards |
| GET | `/trips/mine` | Driver trips |
| GET | `/trips/search` | `origin`, `destination`, `date=YYYY-MM-DD` — rate limited |
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

Set `OTP_PROVIDER` in `.env`:

- `mock` (default) — prints OTP; optional `OTP_MOCK_CODE=123456`
- `msg91` / `2factor` — stubs until DLT templates are live; see `.env.example`

OTP challenges + sessions stay in-memory; **users/trips/bookings require Postgres**.

## Setup

```bash
cp .env.example .env
npm install
npm run migrate
npm run dev
```

Smoke (API running on :3000):

- `./scripts/smoke-phase2.sh` — trip/book/cancel
- `./scripts/smoke-phase3.sh` — rate limits + spam codes
