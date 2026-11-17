# @khalashi/api

Node (Express + TypeScript) API for Khalashi — auth + trips + bookings.

## Endpoints

| Method | Path | Notes |
|--------|------|-------|
| GET | `/health` | Liveness |
| POST | `/auth/otp/request` | `{ "phone": "98XXXXXXXX" }` |
| POST | `/auth/otp/verify` | upserts user in Postgres; returns Bearer token |
| GET | `/auth/me` | Bearer |
| POST | `/auth/logout` | Bearer |
| POST | `/trips` | Offer a ride |
| GET | `/trips/mine` | Driver trips |
| GET | `/trips/search` | `origin`, `destination`, `date=YYYY-MM-DD` |
| GET | `/trips/:id` | Detail |
| POST | `/trips/:id/cancel` | Free cancel until start; cascades bookings |
| GET | `/trips/:id/bookings` | Driver booking list |
| POST | `/trips/:id/bookings` | `{ seats, seatPreference: front\|window\|any }` |
| GET | `/bookings/mine` | Traveller bookings |
| GET | `/bookings/:id` | Detail |
| POST | `/bookings/:id/cancel` | Free cancel until start; restores seats |

Seat booking uses a row lock (`FOR UPDATE`) so concurrent requests cannot oversell.

## OTP providers

Set `OTP_PROVIDER` in `.env`:

- `mock` (default) — prints OTP; optional `OTP_MOCK_CODE=123456`
- `msg91` / `2factor` — stubs until DLT templates are live

OTP challenges + sessions stay in-memory; **users/trips/bookings require Postgres**.

## Setup

```bash
cp .env.example .env
npm install
npm run migrate
npm run dev
```

Smoke: with the API running, `./scripts/smoke-phase2.sh`
