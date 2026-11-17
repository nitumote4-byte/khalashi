# Khalashi

BlaBlaCar-style India carpool for **Nitin Mote Tours & Travel**.

**v1 locked:** trip post + seat book · cash on trip · phone OTP · Hindi + English · driver-set fare · seat preference as request · free cancel until trip start · all India cities.

Stack: **Flutter** mobile · **Node (Express)** API · **PostgreSQL**.

This repo includes **Phase 0–1 (auth shell)** and **Phase 2 (trips + search/book + free cancel)**.

## Monorepo layout

```
apps/
  api/       Express + TypeScript API
  mobile/    Flutter app (HI/EN)
apps/api/migrations/   Postgres schema
```

## Quick start — API

```bash
cd apps/api
cp .env.example .env
npm install
# Start Postgres, then:
npm run migrate
npm run dev
```

### Auth (mock OTP)

- `POST /auth/otp/request` `{ "phone": "9876543210" }` — returns `debugCode` when `OTP_PROVIDER=mock`
- `POST /auth/otp/verify` `{ "phone": "9876543210", "code": "123456" }` → Bearer token
- Users are upserted into Postgres on verify (required for trips/bookings)

### Trips & bookings (Bearer required)

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/trips` | Offer a ride (origin, destination, departAt, seatsTotal, fareInr) |
| GET | `/trips/mine` | Driver’s trips |
| GET | `/trips/search?origin=&destination=&date=YYYY-MM-DD` | Search (normalized city text, IST day) |
| GET | `/trips/:id` | Trip detail |
| POST | `/trips/:id/cancel` | Cancel trip before start (cascades bookings) |
| GET | `/trips/:id/bookings` | Driver: bookings on trip |
| POST | `/trips/:id/bookings` | Book seats `{ seats, seatPreference }` |
| GET | `/bookings/mine` | Traveller bookings |
| GET | `/bookings/:id` | Booking detail |
| POST | `/bookings/:id/cancel` | Cancel booking before start (restores seats) |

Seat booking uses `SELECT … FOR UPDATE` so concurrent books cannot oversell.

**Not in v1 API:** UPI, KYC, maps, chat, ratings.

## Quick start — Mobile

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Flows: language → phone OTP → home → **Find a ride** / **Offer a ride** → search/book or post → my bookings / my trips → free cancel until departure. Cash-on-trip copy throughout; HI + EN.

## Postgres migrations

| File | Purpose |
|------|---------|
| `000_extensions.sql` | `pgcrypto` |
| `001_users.sql` | users |
| `002_trips.sql` | driver trips |
| `003_bookings.sql` | seat bookings |
| `004_otp_challenges.sql` | OTP rows (future) |
| `005_phase2_indexes.sql` | list/search indexes |

## Product docs

Product outline, feature list, wireframes, and tech build plan live in the project Context (`docs/`), not this git tree.

## Phases

| Phase | Focus | Status |
|------:|-------|--------|
| 0–1 | Foundations + OTP auth shell | Done |
| 2 | Trip post + search/book + free cancel | This branch |
| 5 | Soft-launch hardening (city polish, rate limits, store) | Next |
