# @khalashi/api

Node (Express + TypeScript) API for Khalashi Phase 0–1.

## Endpoints (Phase 1 shell)

| Method | Path | Notes |
|--------|------|-------|
| GET | `/health` | Liveness |
| POST | `/auth/otp/request` | `{ "phone": "98XXXXXXXX" }` |
| POST | `/auth/otp/verify` | `{ "phone": "...", "code": "123456" }` |
| GET | `/auth/me` | `Authorization: Bearer <token>` |
| POST | `/auth/logout` | Bearer token |

## OTP providers

Set `OTP_PROVIDER` in `.env`:

- `mock` (default) — prints OTP to console; optional fixed `OTP_MOCK_CODE=123456`
- `msg91` — requires `MSG91_AUTH_KEY`, `MSG91_TEMPLATE_ID`, `MSG91_SENDER_ID`
- `2factor` — requires `TWO_FACTOR_API_KEY`

SMS calls for MSG91/2Factor are stubs until DLT templates are live.

## Setup

```bash
cp .env.example .env
npm install
npm run migrate   # needs Postgres + DATABASE_URL
npm run dev
```

Auth currently uses an in-memory challenge/session store so the shell works without DB. Migrations define `users`, `trips`, `bookings`, `otp_challenges` for later phases.
