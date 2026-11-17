# Khalashi

BlaBlaCar-style India carpool for **Nitin Mote Tours & Travel**.

**v1 locked:** trip post + seat book · cash on trip · phone OTP · Hindi + English · driver-set fare · seat preference as request · free cancel until trip start · all India cities.

Stack: **Flutter** mobile · **Node (Express)** API · **PostgreSQL**.

This repo currently scaffolds **Phase 0 (foundations)** and **Phase 1 (auth shell)** only — not full booking.

## Monorepo layout

```
apps/
  api/       Express + TypeScript API (health, OTP auth stubs)
  mobile/    Flutter app (HI/EN, splash, OTP, home Find/Offer stubs)
apps/api/migrations/   Postgres schema stubs (users, trips, bookings, otp)
```

## Quick start — API

```bash
cd apps/api
cp .env.example .env
npm install
# Optional: start Postgres and set DATABASE_URL, then:
# npm run migrate
npm run dev
```

- Health: `GET http://localhost:3000/health`
- OTP (mock): `POST /auth/otp/request` `{ "phone": "9876543210" }` — code logged / returned as `debugCode` when `OTP_PROVIDER=mock`
- Verify: `POST /auth/otp/verify` `{ "phone": "9876543210", "code": "123456" }`

SMS: set `OTP_PROVIDER=msg91` or `2factor` and fill keys in `.env` (stubs until DLT templates are live).

## Quick start — Mobile

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

First launch: language (हिंदी / English) → phone → OTP → home with **Find a ride** / **Offer a ride** stubs.

## Postgres

SQL migrations in `apps/api/migrations/`:

| File | Purpose |
|------|---------|
| `000_extensions.sql` | `pgcrypto` |
| `001_users.sql` | users (phone, language) |
| `002_trips.sql` | driver trips |
| `003_bookings.sql` | seat bookings |
| `004_otp_challenges.sql` | OTP challenge rows |

Apply with `npm run migrate` from `apps/api` when Postgres is available.

Phase 1 auth uses an in-memory challenge/session store so the shell works without DB; tables are ready for Phase 2+.

## Product docs

Product outline, feature list, wireframes, and tech build plan live in the project Context (`docs/`), not this git tree.

## Phases (next)

| Phase | Focus |
|------:|-------|
| 2 | Driver post trip + my trips |
| 3 | Search + atomic seat book |
| 4 | Cancel rules until trip start |
| 5 | Soft-launch hardening |
